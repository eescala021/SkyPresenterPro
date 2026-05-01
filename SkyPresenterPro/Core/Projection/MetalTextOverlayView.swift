import AppKit
import CoreImage
import Metal
import MetalKit
import SwiftUI

struct MetalTextOverlayView: NSViewRepresentable {
    let layout: TextRenderLayout

    func makeCoordinator() -> Coordinator {
        Coordinator(layout: layout)
    }

    func makeNSView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = context.coordinator.device
        view.delegate = context.coordinator
        view.framebufferOnly = false
        view.enableSetNeedsDisplay = true
        view.isPaused = true
        view.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        view.colorPixelFormat = .bgra8Unorm
        view.layer?.isOpaque = false
        view.wantsLayer = true
        return view
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        context.coordinator.update(layout: layout)
        nsView.setNeedsDisplay(nsView.bounds)
    }

    final class Coordinator: NSObject, MTKViewDelegate {
        let device: MTLDevice?
        private let commandQueue: MTLCommandQueue?
        private let ciContext: CIContext?
        private var layout: TextRenderLayout
        private var cachedKey: String?
        private var cachedImage: CIImage?

        init(layout: TextRenderLayout) {
            self.device = MTLCreateSystemDefaultDevice()
            self.commandQueue = device?.makeCommandQueue()
            if let device {
                self.ciContext = CIContext(mtlDevice: device)
            } else {
                self.ciContext = nil
            }
            self.layout = layout
        }

        func update(layout: TextRenderLayout) {
            guard self.layout != layout else { return }
            self.layout = layout
            cachedKey = nil
            cachedImage = nil
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            cachedKey = nil
            cachedImage = nil
        }

        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let descriptor = view.currentRenderPassDescriptor,
                  let commandQueue,
                  let commandBuffer = commandQueue.makeCommandBuffer() else {
                return
            }

            descriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
            descriptor.colorAttachments[0].loadAction = .clear
            descriptor.colorAttachments[0].storeAction = .store

            if let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) {
                encoder.endEncoding()
            }

            let size = view.drawableSize
            if let image = image(for: layout, size: size),
               let ciContext {
                ciContext.render(
                    image,
                    to: drawable.texture,
                    commandBuffer: commandBuffer,
                    bounds: CGRect(origin: .zero, size: size),
                    colorSpace: CGColorSpaceCreateDeviceRGB()
                )
            }

            commandBuffer.present(drawable)
            commandBuffer.commit()
        }

        private func image(for layout: TextRenderLayout, size: CGSize) -> CIImage? {
            guard size.width > 1, size.height > 1 else { return nil }

            let key = "\(layout.cacheSignature)|\(Int(size.width))x\(Int(size.height))"
            if cachedKey == key {
                return cachedImage
            }

            guard let cgImage = Self.renderLayout(layout, size: size) else {
                return nil
            }

            let image = CIImage(cgImage: cgImage)
            cachedKey = key
            cachedImage = image
            return image
        }

        @MainActor
        private static func renderLayout(_ layout: TextRenderLayout, size: CGSize) -> CGImage? {
            let rootView = TextRenderEngineView(layout: layout)
                .frame(width: size.width, height: size.height)
                .background(Color.clear)

            let hostingView = NSHostingView(rootView: rootView)
            hostingView.frame = CGRect(origin: .zero, size: size)
            hostingView.wantsLayer = true
            hostingView.layer?.backgroundColor = NSColor.clear.cgColor
            hostingView.layoutSubtreeIfNeeded()

            guard let bitmap = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
                return nil
            }

            bitmap.size = hostingView.bounds.size
            hostingView.cacheDisplay(in: hostingView.bounds, to: bitmap)
            return bitmap.cgImage
        }
    }
}

private extension TextRenderLayout {
    var cacheSignature: String {
        [
            title?.cacheSignature ?? "",
            lines.map(\.cacheSignature).joined(separator: "\u{001F}"),
            comment?.cacheSignature ?? "",
            reference?.cacheSignature ?? "",
            String(format: "%.4f", maxWidthFraction),
            String(format: "%.4f", verticalOffset),
            String(format: "%.4f", spacing),
            String(format: "%.4f", margin),
            textBoxMode.rawValue,
            referencePosition.rawValue
        ].joined(separator: "\u{001E}")
    }
}

private extension TextRenderBlock {
    var cacheSignature: String {
        [
            text,
            "\(role)",
            color.cacheSignature,
            alignment.cacheSignature,
            String(format: "%.4f", scaleFactor),
            box?.cacheSignature ?? "",
            shadow?.cacheSignature ?? "",
            outline?.cacheSignature ?? "",
            glow?.cacheSignature ?? "",
            String(format: "%.4f", tracking)
        ].joined(separator: "|")
    }
}

private extension TextRenderBox {
    var cacheSignature: String {
        [
            color.cacheSignature,
            String(format: "%.4f", opacity),
            String(format: "%.4f", horizontalPadding),
            String(format: "%.4f", verticalPadding),
            String(format: "%.4f", cornerRadius)
        ].joined(separator: ",")
    }
}

private extension TextRenderShadow {
    var cacheSignature: String {
        [
            color.cacheSignature,
            String(format: "%.4f", radius),
            String(format: "%.4f", x),
            String(format: "%.4f", y)
        ].joined(separator: ",")
    }
}

private extension TextRenderOutline {
    var cacheSignature: String {
        "\(color.cacheSignature),\(String(format: "%.4f", width))"
    }
}

private extension TextRenderGlow {
    var cacheSignature: String {
        "\(color.cacheSignature),\(String(format: "%.4f", radius))"
    }
}

private extension Color {
    var cacheSignature: String {
        let color = NSColor(self).usingColorSpace(.deviceRGB) ?? .clear
        return String(
            format: "%.4f,%.4f,%.4f,%.4f",
            color.redComponent,
            color.greenComponent,
            color.blueComponent,
            color.alphaComponent
        )
    }
}

private extension TextAlignment {
    var cacheSignature: String {
        switch self {
        case .leading: return "leading"
        case .center: return "center"
        case .trailing: return "trailing"
        }
    }
}

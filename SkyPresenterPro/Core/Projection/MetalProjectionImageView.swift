import CoreImage
import Metal
import MetalKit
import SwiftUI

struct MetalProjectionImageView: NSViewRepresentable {
    let path: String
    let contentMode: ContentMode

    func makeCoordinator() -> Coordinator {
        Coordinator(path: path, contentMode: contentMode)
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
        context.coordinator.update(path: path, contentMode: contentMode)
        nsView.setNeedsDisplay(nsView.bounds)
    }

    final class Coordinator: NSObject, MTKViewDelegate {
        let device: MTLDevice?
        private let commandQueue: MTLCommandQueue?
        private let ciContext: CIContext?
        private var path: String
        private var contentMode: ContentMode

        init(path: String, contentMode: ContentMode) {
            self.device = MTLCreateSystemDefaultDevice()
            self.commandQueue = device?.makeCommandQueue()
            if let device {
                self.ciContext = CIContext(mtlDevice: device)
            } else {
                self.ciContext = nil
            }
            self.path = path
            self.contentMode = contentMode
        }

        func update(path: String, contentMode: ContentMode) {
            self.path = path
            self.contentMode = contentMode
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        func draw(in view: MTKView) {
            ProjectionRenderDiagnostics.shared.record(.metalImageDraw)

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

            let drawableSize = view.drawableSize
            if let image = MetalProjectionImageCache.shared.image(at: path),
               let ciContext {
                let fittedImage = image.transformedToFill(
                    size: drawableSize,
                    contentMode: contentMode
                )
                ciContext.render(
                    fittedImage,
                    to: drawable.texture,
                    commandBuffer: commandBuffer,
                    bounds: CGRect(origin: .zero, size: drawableSize),
                    colorSpace: CGColorSpaceCreateDeviceRGB()
                )
            } else {
                ProjectionRenderDiagnostics.shared.record(.metalImageRenderFailure)
            }

            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}

private final class MetalProjectionImageCache {
    static let shared = MetalProjectionImageCache()

    private final class Box {
        let image: CIImage

        init(_ image: CIImage) {
            self.image = image
        }
    }

    private let cache = NSCache<NSString, Box>()

    private init() {
        cache.countLimit = 48
        cache.totalCostLimit = 384 * 1024 * 1024
    }

    func image(at path: String) -> CIImage? {
        if let cached = cache.object(forKey: path as NSString)?.image {
            ProjectionRenderDiagnostics.shared.record(.metalImageCacheHit)
            return cached
        }

        ProjectionRenderDiagnostics.shared.record(.metalImageCacheMiss)
        let url = URL(fileURLWithPath: path)
        guard let image = CIImage(contentsOf: url, options: [.applyOrientationProperty: true]) else {
            return nil
        }

        cache.setObject(Box(image), forKey: path as NSString, cost: image.cacheCost)
        return image
    }
}

private extension CIImage {
    func transformedToFill(size: CGSize, contentMode: ContentMode) -> CIImage {
        let source = extent
        guard source.width > 0, source.height > 0, size.width > 0, size.height > 0 else {
            return self
        }

        let xScale = size.width / source.width
        let yScale = size.height / source.height
        let scale: CGFloat

        switch contentMode {
        case .fit:
            scale = min(xScale, yScale)
        case .fill:
            scale = max(xScale, yScale)
        @unknown default:
            scale = min(xScale, yScale)
        }

        let scaledWidth = source.width * scale
        let scaledHeight = source.height * scale
        let x = (size.width - scaledWidth) / 2
        let y = (size.height - scaledHeight) / 2

        return transformed(by: CGAffineTransform(translationX: -source.minX, y: -source.minY))
            .transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            .transformed(by: CGAffineTransform(translationX: x, y: y))
    }

    var cacheCost: Int {
        max(1, Int(extent.width * extent.height * 4))
    }
}

import Metal
import MetalKit
import SwiftUI

struct MetalProjectionBackdropView: NSViewRepresentable {
    var clearColor: MTLClearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)

    func makeCoordinator() -> Coordinator {
        Coordinator(clearColor: clearColor)
    }

    func makeNSView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = context.coordinator.device
        view.delegate = context.coordinator
        view.framebufferOnly = true
        view.enableSetNeedsDisplay = true
        view.isPaused = true
        view.clearColor = clearColor
        view.colorPixelFormat = .bgra8Unorm
        view.preferredFramesPerSecond = 60
        return view
    }

    func updateNSView(_ nsView: MTKView, context: Context) {
        nsView.clearColor = clearColor
        context.coordinator.clearColor = clearColor
        nsView.setNeedsDisplay(nsView.bounds)
    }

    final class Coordinator: NSObject, MTKViewDelegate {
        let device: MTLDevice?
        private let commandQueue: MTLCommandQueue?
        var clearColor: MTLClearColor

        init(clearColor: MTLClearColor) {
            self.device = MTLCreateSystemDefaultDevice()
            self.commandQueue = device?.makeCommandQueue()
            self.clearColor = clearColor
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}

        func draw(in view: MTKView) {
            guard let drawable = view.currentDrawable,
                  let descriptor = view.currentRenderPassDescriptor,
                  let commandBuffer = commandQueue?.makeCommandBuffer() else {
                return
            }

            descriptor.colorAttachments[0].clearColor = clearColor
            descriptor.colorAttachments[0].loadAction = .clear
            descriptor.colorAttachments[0].storeAction = .store

            if let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor) {
                encoder.endEncoding()
            }

            commandBuffer.present(drawable)
            commandBuffer.commit()
        }
    }
}

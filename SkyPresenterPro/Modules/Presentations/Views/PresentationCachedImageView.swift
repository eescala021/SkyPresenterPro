import AppKit
import SwiftUI

struct PresentationCachedImageView<Placeholder: View>: View {
    let path: String?
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                placeholder()
            }
        }
        .onAppear(perform: loadImage)
        .onChange(of: path) { _, _ in
            loadImage()
        }
    }

    private func loadImage() {
        image = PresentationThumbnailService.shared.cachedImage(at: path)
    }
}

import PDFKit
import SwiftUI

/// Tarjeta de diapositiva en la cuadrícula del área de trabajo.
/// Muestra la miniatura de la página PDF y el número de diapositiva.
struct PresentationSlideCard: View {
    let slide: PresentationSlide
    let document: PresentationDocument
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .center, spacing: AppSpacing.sm) {
            PresentationThumbnailView(
                document: document,
                slideIndex: slide.pageIndex
            )
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.sm))

            Text("Diapositiva \(slide.pageNumber)")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
        }
        .modifier(AppCardStyle())
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.md)
                .stroke(isSelected ? AppColors.accent : .clear, lineWidth: 1.5)
        )
    }
}

// MARK: - PresentationThumbnailView

/// Vista auxiliar que genera y muestra la miniatura de una página PDF bajo demanda.
/// Usada tanto en PresentationSlideCard como en PresentationSlidesStrip.
struct PresentationThumbnailView: View {
    let document: PresentationDocument
    let slideIndex: Int

    @State private var thumbnail: NSImage?

    var body: some View {
        Group {
            if let thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ZStack {
                    Color.black.opacity(0.55)
                    Text("Diap. \(slideIndex + 1)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
        }
        .task {
            thumbnail = await generateThumbnail()
        }
    }

    private func generateThumbnail() async -> NSImage? {
        guard let url = document.fileURL else { return nil }
        return await Task.detached(priority: .userInitiated) {
            guard let pdf = PDFDocument(url: url),
                  let page = pdf.page(at: slideIndex) else { return nil }
            return page.thumbnail(of: CGSize(width: 320, height: 180), for: .mediaBox)
        }.value
    }
}

import SwiftUI

/// Tarjeta de previsualización de diapositiva en el panel En directo.
/// Muestra el estado de la diapositiva actual o siguiente del ProjectionEngine.
struct PresentationPreviewCard: View {
    let title: String
    let slide: ProjectionSlide?
    var height: CGFloat = 150

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(.headline)

            ProjectionPreviewSurface(slide: slide)
                .frame(height: height)
        }
        .modifier(AppCardStyle())
    }
}

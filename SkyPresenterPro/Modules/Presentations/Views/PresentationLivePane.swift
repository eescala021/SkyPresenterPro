import SwiftUI

struct PresentationLivePane: View {
    @EnvironmentObject private var viewModel: PresentationViewModel

    var body: some View {
        PresentationDetectedVersePane {
            header
            Divider()
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("VERSÍCULO DETECTADO")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            Text("⌘P PROYECTAR")
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.blue.opacity(0.10)))
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.detectedReferences.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Sin referencia en este slide")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)

                Text("Las referencias bíblicas detectadas en el título o en las notas aparecen aquí automáticamente.")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(viewModel.detectedReferences) { ref in
                        referenceRow(ref)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }

    private func referenceRow(_ detectedReference: PresentationDetectedReference) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            PresentationAdaptiveText(
                text: detectedReference.displayReference,
                style: .reference,
                font: .system(size: 12, weight: .black),
                color: .primary,
                lineLimit: 1
            )

            PresentationAdaptiveText(
                text: detectedReference.matchedText,
                style: .generic,
                font: .system(size: 11, weight: .regular),
                color: .secondary,
                lineLimit: 4
            )
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.white))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
    }
}

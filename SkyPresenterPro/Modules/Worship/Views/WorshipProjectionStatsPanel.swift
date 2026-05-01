import SwiftUI

struct WorshipProjectionStatsPanel: View {
    @EnvironmentObject private var viewModel: WorshipViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()

            if viewModel.projectionStatistics.isEmpty {
                WorshipEmptyStateView(text: "Todavía no hay proyecciones registradas.")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(showsIndicators: true) {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(viewModel.projectionStatistics.enumerated()), id: \.element.id) { index, stat in
                            statRow(stat, rank: index + 1)
                        }
                    }
                    .padding(14)
                }
            }
        }
        .frame(minWidth: 520, minHeight: 420)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Estadísticas de proyección")
                    .font(.system(size: 18, weight: .black))

                Text("Conteo acumulado de canciones proyectadas desde Alabanzas")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            totalChip

            Button("Cerrar") {
                dismiss()
            }
            .buttonStyle(SecondaryActionButtonStyle())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var totalChip: some View {
        Text("\(viewModel.totalProjectionCount) proyecciones")
            .font(.system(size: 11, weight: .black))
            .foregroundStyle(.blue)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.blue.opacity(0.12)))
    }

    private func statRow(_ stat: WorshipProjectionStatistic, rank: Int) -> some View {
        HStack(spacing: 10) {
            Text(String(format: "%02d", rank))
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 3) {
                Text(stat.title)
                    .font(.system(size: 12, weight: .black))
                    .lineLimit(1)

                Text(stat.artist.isEmpty ? "Sin artista" : stat.artist)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text("\(stat.count)")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(.green)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.green.opacity(0.12)))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
    }
}

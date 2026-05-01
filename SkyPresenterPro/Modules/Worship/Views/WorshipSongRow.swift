// Archivo: WorshipSongRow.swift
// Función: Fila compacta de canción dentro de la biblioteca de Alabanzas.
// Contiene: WorshipSongRow.
// Uso: Una sola línea horizontal con indicador, título y artista — sin segunda fila de metadata.

import SwiftUI

struct WorshipSongRow: View {
    let song: WorshipSong
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isSelected ? AppColors.accent : Color.secondary.opacity(0.20))
                .frame(width: 8, height: 8)

            Text(song.title)
                .font(.system(size: 13, weight: isSelected ? .black : .semibold))
                .lineLimit(1)

            Text("·")
                .foregroundStyle(.secondary)

            Text(song.artist)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer()

            if isSelected {
                Text("\(song.sections.count)")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.blue.opacity(0.12)))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(isSelected ? Color.white.opacity(0.95) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(isSelected ? AppColors.accent.opacity(0.45) : Color.clear, lineWidth: 1.5)
        )
    }
}

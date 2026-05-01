// Archivo: PresentationSlidesStrip.swift
// Función: Tira horizontal compacta de slides del documento activo.
// Contiene: PresentationSlidesStrip.
// Uso: Banda de navegación rápida sin cabeceras redundantes. Click prepara, doble-click proyecta.

import SwiftUI

struct PresentationSlidesStrip: View {
    @EnvironmentObject private var viewModel: PresentationViewModel

    let document: PresentationDocument

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: true) {
                LazyHStack(spacing: 6) {
                    ForEach(document.slides) { slide in
                        PresentationSlideCard(slide: slide)
                            .frame(width: 108, height: 130)
                            .id(slide.id)
                            .help("Click: preparar · Doble click: proyectar")
                            .onTapGesture {
                                viewModel.prepareSlide(slide)
                            }
                            .onTapGesture(count: 2) {
                                viewModel.prepareSlide(slide)
                                viewModel.projectPreparedSlide()
                            }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .defaultScrollAnchor(.leading)
            .onAppear {
                scrollToRelevantSlide(with: proxy, animated: false)
            }
            .onChange(of: viewModel.liveState.preparedSlideID) { _, _ in
                scrollToRelevantSlide(with: proxy)
            }
            .onChange(of: viewModel.liveState.projectedSlideID) { _, _ in
                scrollToRelevantSlide(with: proxy)
            }
            .onChange(of: document.id) { _, _ in
                scrollToRelevantSlide(with: proxy, animated: false)
            }
        }
        .frame(height: 140)
        .background(
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .fill(Color.white.opacity(0.6))
        )
    }

    private func scrollToRelevantSlide(with proxy: ScrollViewProxy, animated: Bool = true) {
        let targetID = viewModel.liveState.projectedSlideID
            ?? viewModel.liveState.preparedSlideID
            ?? viewModel.liveState.selectedSlideID

        guard let targetID else { return }

        if animated {
            withAnimation(.easeInOut(duration: 0.22)) {
                proxy.scrollTo(targetID, anchor: .center)
            }
        } else {
            proxy.scrollTo(targetID, anchor: .center)
        }
    }
}

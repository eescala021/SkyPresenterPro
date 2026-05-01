// Archivo: PresentationViewModel.swift
// Función: Coordina el estado del módulo Presentaciones.
// Contiene: PresentationViewModel.
// Uso: Controla biblioteca, selección, preparación, proyección y detección de referencias bíblicas dentro de slides.
//      Persiste automáticamente los cambios a través de PresentationRepository.
//      Expone goNext(), goPrevious() y clearProjection() para control remoto vía RemoteCommandBus.

import Combine
import SwiftUI

@MainActor
final class PresentationViewModel: ObservableObject {
    private let repository: PresentationRepository
    private let queueService = PresentationQueueService()
    private let verseDetectionService = PresentationVerseDetectionService()

    @Published var documents: [PresentationDocument] = []
    @Published var searchText: String = ""
    @Published var liveState = PresentationLiveState()
    @Published var detectedReferences: [PresentationDetectedReference] = []
    @Published var isShowingImportWindow: Bool = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        self.repository = DefaultPresentationRepository()
        loadDocuments()
        subscribeToRemoteCommands()
    }

    init(repository: PresentationRepository) {
        self.repository = repository
        loadDocuments()
        subscribeToRemoteCommands()
    }

    // MARK: - Computed

    var filteredDocuments: [PresentationDocument] {
        guard !searchText.isEmpty else { return documents }
        return documents.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.sourceFileName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var selectedDocument: PresentationDocument? {
        documents.first(where: { $0.id == liveState.currentDocumentID })
    }

    var selectedSlide: PresentationSlide? {
        selectedDocument?.slides.first(where: { $0.id == liveState.selectedSlideID })
    }

    var preparedSlide: PresentationSlide? {
        selectedDocument?.slides.first(where: { $0.id == liveState.preparedSlideID })
    }

    var projectedSlide: PresentationSlide? {
        selectedDocument?.slides.first(where: { $0.id == liveState.projectedSlideID })
    }

    var currentProjectionSlides: [ProjectionSlide]? {
        guard let document = selectedDocument else { return nil }
        return PresentationSlidesBuilder.build(document: document)
    }

    // MARK: - Load

    func loadDocuments() {
        documents = repository.loadDocuments()

        if let first = documents.first {
            selectDocument(first)
        }
    }

    // MARK: - Add / Remove

    /// Agrega un documento importado a la biblioteca, lo selecciona y persiste la lista.
    func addDocument(_ document: PresentationDocument) {
        guard !documents.contains(where: { $0.id == document.id }) else { return }
        documents.append(document)
        persistDocuments()
        selectDocument(document)
    }

    /// Elimina un documento de la biblioteca por su identificador y persiste la lista.
    func removeDocument(id: UUID) {
        documents.removeAll { $0.id == id }

        if liveState.currentDocumentID == id {
            liveState = PresentationLiveState()
            if let first = documents.first {
                selectDocument(first)
            }
        }

        persistDocuments()
    }

    // MARK: - Selection

    func selectDocument(_ document: PresentationDocument) {
        liveState.currentDocumentID = document.id
        liveState.selectedSlideID = document.slides.first?.id
        liveState.preparedSlideID = document.slides.first?.id

        if liveState.projectedSlideID == nil {
            liveState.projectedSlideID = document.slides.first?.id
        }

        refreshDetectedReferences()
        publishCurrentSlide()
    }

    func selectSlide(_ slide: PresentationSlide) {
        liveState.selectedSlideID = slide.id
        liveState.preparedSlideID = slide.id
        refreshDetectedReferences()
    }

    func markProjected(_ slide: PresentationSlide) {
        liveState.projectedSlideID = slide.id
        publishCurrentSlide()
    }

    // MARK: - Remote Control API

    /// Avanza al siguiente slide. Llamable desde RemoteCommandBus.
    func goNext() {
        guard let document = selectedDocument,
              let selectedSlide,
              let index = document.slides.firstIndex(where: { $0.id == selectedSlide.id }),
              index + 1 < document.slides.count
        else { return }

        let next = document.slides[index + 1]
        selectSlide(next)
        markProjected(next)
    }

    /// Retrocede al slide anterior. Llamable desde RemoteCommandBus.
    func goPrevious() {
        guard let document = selectedDocument,
              let selectedSlide,
              let index = document.slides.firstIndex(where: { $0.id == selectedSlide.id }),
              index > 0
        else { return }

        let prev = document.slides[index - 1]
        selectSlide(prev)
        markProjected(prev)
    }

    /// Limpia la proyección activa (projectedSlideID → nil). Llamable desde RemoteCommandBus.
    func clearProjection() {
        liveState.projectedSlideID = nil
        RemoteCommandBus.shared.updateCurrentSlide("{\"title\":null,\"index\":null,\"source\":\"none\"}")
    }

    // MARK: - Navigation (alias mantenidos para compatibilidad interna)

    func goToPreviousSlide() { goPrevious() }
    func goToNextSlide()     { goNext() }

    // MARK: - Queue

    func addToQueue(_ document: PresentationDocument) {
        queueService.add(document)
    }

    // MARK: - Detection

    func refreshDetectedReferences() {
        guard let slide = selectedSlide else {
            detectedReferences = []
            return
        }

        let detectionTexts = candidateTextsForDetection(from: slide)
        detectedReferences = verseDetectionService.detectReferences(
            in: detectionTexts,
            pageIndex: slide.pageIndex
        )
    }

    private func candidateTextsForDetection(from slide: PresentationSlide) -> [String] {
        var values: [String] = []

        if let title = slide.title, !title.isEmpty {
            values.append(title)
        }

        if !slide.notes.isEmpty {
            values.append(contentsOf: slide.notes)
        }

        if values.isEmpty {
            values.append("Página \(slide.pageIndex + 1)")
        }

        return values
    }

    // MARK: - Helpers

    func detectedReference(for id: UUID) -> PresentationDetectedReference? {
        detectedReferences.first(where: { $0.id == id })
    }

    // MARK: - Persistence

    private func persistDocuments() {
        repository.saveDocuments(documents)
    }

    // MARK: - Remote Command Bus

    /// Suscribe al bus de comandos remotos para recibir acciones desde el servidor HTTP.
    private func subscribeToRemoteCommands() {
        RemoteCommandBus.shared.publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] command in
                switch command {
                case .nextSlide:     self?.goNext()
                case .previousSlide: self?.goPrevious()
                case .clearOutput:   self?.clearProjection()
                default:             break
                }
            }
            .store(in: &cancellables)
    }

    /// Publica el estado del slide actual al RemoteCommandBus para que /status y /current lo sirvan.
    private func publishCurrentSlide() {
        guard let slide = projectedSlide ?? selectedSlide else {
            RemoteCommandBus.shared.updateCurrentSlide(
                "{\"title\":null,\"index\":null,\"source\":\"presentation\"}"
            )
            return
        }

        let title = (slide.title ?? "Página \(slide.pageIndex + 1)")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let json = """
        {"title":"\(title)","index":\(slide.pageIndex),"source":"presentation"}
        """
        RemoteCommandBus.shared.updateCurrentSlide(json)
    }
}

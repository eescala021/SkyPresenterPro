import SwiftUI

enum PageItem: Hashable {
    case number(Int)
    case next
    case prev
}

struct BibleView: View {
    @EnvironmentObject var displayManager: DisplayManager
    @EnvironmentObject var bibleManager: BibleManager

    @ObservedObject var viewState: BibleViewState
    @FocusState private var isSearchFocused: Bool
    @State private var showingLibrarySheet: Bool = false
    @State private var showingEditBibleSheet: Bool = false
    @State private var importName: String = ""
    @State private var importAlias: String = ""
    @State private var importLanguage: BibleLanguageOption = .spanish
    @State private var editTargetID: UUID?
    @State private var editName: String = ""
    @State private var editAlias: String = ""
    @State private var editLanguage: BibleLanguageOption = .spanish

    private let bookColumns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 11)
    private let chapterColumns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 10)
    private let verseColumns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 8)

    var body: some View {
        GeometryReader { geometry in
            let isCompactHeight = geometry.size.height < 760

            VStack(spacing: 8) {
                headerBar

                HStack(alignment: .top, spacing: 8) {
                    versePanel
                        .frame(width: min(max(380, geometry.size.width * 0.33), 470))

                    VStack(spacing: 0) {
                        booksPanel
                            .frame(height: isCompactHeight ? geometry.size.height * 0.50 : geometry.size.height * 0.52)

                        HStack(spacing: 8) {
                            chaptersPanel
                            versesPanel
                        }
                        .padding(.top, 2)
                        .padding(.bottom, 10)
                        .frame(maxHeight: .infinity)
                    }
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.89, green: 0.92, blue: 0.96))
        }
        .sheet(isPresented: $showingLibrarySheet) {
            librarySheet
        }
        .sheet(isPresented: $showingEditBibleSheet) {
            editBibleSheet
        }
        .onAppear {
            viewState.configure(bibleManager: bibleManager, displayManager: displayManager)
            DispatchQueue.main.async {
                isSearchFocused = true
            }
        }
    }

    private var currentVersion: BibleVersionSlot? {
        viewState.currentVersion
    }

    private var currentBook: BibleBookMetadata? {
        viewState.currentBook
    }

    private var currentVerses: [Verse] {
        viewState.currentVerses
    }

    private var visibleBookIndexes: [Int] {
        viewState.visibleBookIndexes
    }

    private var chapterPageCount: Int {
        viewState.chapterPageCount
    }

    private var versePageCount: Int {
        viewState.versePageCount
    }

    private var chapterItems: [PageItem] {
        viewState.chapterItems
    }

    private var verseItems: [PageItem] {
        viewState.verseItems
    }

    private var chapterNeedsPagination: Bool {
        viewState.chapterNeedsPagination
    }

    private var verseNeedsPagination: Bool {
        viewState.verseNeedsPagination
    }

    private var headerBar: some View {
        VStack(spacing: 5) {
            HStack(alignment: .center, spacing: 8) {
                versionSelector
                Spacer(minLength: 0)
                searchBar
                quickJumpBar
                Button(action: { displayManager.clearProjection() }) {
                    Text("Limpiar")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.30, green: 0.34, blue: 0.42))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.92))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            HStack(alignment: .center, spacing: 8) {
                Text(selectionTitle)
                    .font(.system(size: 20, weight: .heavy, design: .serif))
                    .foregroundColor(Color(red: 0.20, green: 0.24, blue: 0.30))
                    .lineLimit(1)

                if currentVersion?.sourceBadge != nil, displayManager.bibleProjectionSettings.showsImportBadge {
                    Text("IMPORTADO")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(Color(red: 0.14, green: 0.46, blue: 0.76))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.92))
                        .clipShape(Capsule())
                }

                Text("Clic: seleccionar. Doble clic: proyectar.")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(red: 0.40, green: 0.44, blue: 0.52))

                Spacer(minLength: 0)

                bibleStatusText(title: "Capítulos", value: "\(viewState.currentChapterCount)")
                bibleStatusText(title: "Versículos", value: "\(currentVerses.count)")
                bibleStatusText(title: "Selección", value: currentSelectionLabel)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(toolbarBackground)
        .animation(.easeInOut(duration: 0.20), value: viewState.selectedBookIndex)
        .animation(.easeInOut(duration: 0.20), value: viewState.selectedChapter)
        .animation(.easeInOut(duration: 0.20), value: viewState.selectedVerse)
        .simultaneousGesture(TapGesture().onEnded {
            dismissSearchFocus()
        })
    }

    private var versionSelector: some View {
        HStack(spacing: 8) {
            ForEach(bibleManager.versions) { version in
                BibleVersionCard(
                    title: version.title,
                    subtitle: version.language.isEmpty ? "SIN IDIOMA" : version.language,
                    isSelected: viewState.selectedVersionIndex == version.id,
                    emphasizesSelection: displayManager.bibleProjectionSettings.emphasizesSelectedVersion,
                    background: versionBackground(for: version.id)
                ) {
                    dismissSearchFocus()
                    viewState.selectVersion(version.id)
                }
                .contextMenu {
                    Button("Seleccionar \(version.title)") {
                        viewState.selectVersion(version.id)
                    }

                    Menu("Asignar desde biblioteca") {
                        ForEach(bibleManager.library) { item in
                            Button("\(item.displayTitle) · \(item.language)") {
                                bibleManager.assignLibraryItem(item.id, toSlot: version.id)
                                if viewState.selectedVersionIndex == version.id {
                                    viewState.resetSelectionForVersion()
                                }
                            }
                        }
                    }

                    Button("Vaciar slot", role: .destructive) {
                        bibleManager.resetVersion(at: version.id)
                        if viewState.selectedVersionIndex == version.id {
                            viewState.resetSelectionForVersion()
                        }
                    }
                }
            }

            Button(action: {
                dismissSearchFocus()
                importName = ""
                importAlias = ""
                importLanguage = .spanish
                showingLibrarySheet = true
            }) {
                Label("Biblioteca", systemImage: "books.vertical")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.30, green: 0.46, blue: 0.70), Color(red: 0.21, green: 0.34, blue: 0.58)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private var searchBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("Buscar")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(red: 0.47, green: 0.52, blue: 0.60))

                Divider()
                    .frame(height: 18)

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color(red: 0.52, green: 0.56, blue: 0.64))

                TextField(viewState.searchPlaceholder, text: $viewState.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium))
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .focused($isSearchFocused)
                    .onSubmit {
                        dismissSearchFocus()
                        viewState.applySearchQuery()
                    }

                Button("Ir") {
                    dismissSearchFocus()
                    viewState.applySearchQuery()
                }
                .buttonStyle(.plain)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(red: 0.23, green: 0.35, blue: 0.61))
                .keyboardShortcut(.return, modifiers: [.command])
            }

            HStack(spacing: 8) {
                Label("Referencias directas: Gn 1:1, Jn 3:16, 1 Cor 13", systemImage: "sparkle.magnifyingglass")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(red: 0.46, green: 0.50, blue: 0.58))

                Spacer(minLength: 0)

                if !viewState.lastSearchFeedback.isEmpty {
                    Text(viewState.lastSearchFeedback)
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(Color(red: 0.23, green: 0.35, blue: 0.61))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.92))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .frame(width: 360)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(red: 0.79, green: 0.82, blue: 0.88), lineWidth: 1)
        )
    }

    private var quickJumpBar: some View {
        HStack(spacing: 8) {
            Text("#")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color(red: 0.44, green: 0.49, blue: 0.58))

            Text("Ir a capítulo")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(red: 0.44, green: 0.49, blue: 0.58))

            TextField("Cap.", text: $viewState.quickJumpText)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 38)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Button("Ir") {
                dismissSearchFocus()
                viewState.jumpToChapter()
            }
            .buttonStyle(.plain)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(red: 0.31, green: 0.42, blue: 0.57))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.84))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(red: 0.79, green: 0.82, blue: 0.88), lineWidth: 1)
        )
    }

    private var versePanel: some View {
        BiblePanelCard(title: currentBookTitle, subtitle: "", background: panelBackground, compactHeader: true, centeredHeader: true, showsSubtitle: false) {
            VStack(spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentSelectionLabel)
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(red: 0.20, green: 0.24, blue: 0.30))
                        Text("Selecciona un versículo o usa doble clic para enviarlo al proyector.")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color(red: 0.45, green: 0.49, blue: 0.56))
                    }

                    Spacer(minLength: 0)

                    VStack(alignment: .trailing, spacing: 6) {
                        Button(viewState.isSelectedVerseFavorite ? "Quitar favorito" : "Guardar favorito") {
                            guard let verse = viewState.selectedVerse else { return }
                            dismissSearchFocus()
                            viewState.toggleFavorite(for: verse)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .disabled(viewState.selectedVerse == nil)

                        Text("\(currentVerses.count) versículos")
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundColor(Color(red: 0.23, green: 0.35, blue: 0.61))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.88))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 2)

                if currentVerses.isEmpty {
                    Spacer(minLength: 20)
                    Text(emptyBibleMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer(minLength: 0)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 6) {
                                ForEach(currentVerses, id: \.number) { verse in
                                    verseRow(verse)
                                        .id(verse.number)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.bottom, 10)
                        }
                        .scrollIndicators(.visible)
                        .onChange(of: viewState.selectedVerse) { _, verse in
                            guard let verse else { return }
                            proxy.scrollTo(verse, anchor: .center)
                        }
                        .onChange(of: viewState.selectedChapter) { _, _ in
                            if let verse = viewState.selectedVerse {
                                proxy.scrollTo(verse, anchor: .center)
                            } else if let firstVerse = currentVerses.first?.number {
                                proxy.scrollTo(firstVerse, anchor: .top)
                            }
                        }
                    }
                }

                if !viewState.favorites.isEmpty {
                    Divider()
                        .padding(.horizontal, 10)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Favoritos")
                                    .font(.system(size: 12, weight: .heavy))
                                    .foregroundColor(Color(red: 0.42, green: 0.46, blue: 0.53))
                                Text("Accesos rápidos para predicación y lectura continua.")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Color(red: 0.54, green: 0.58, blue: 0.65))
                            }

                            Spacer(minLength: 0)

                            Text("\(viewState.favorites.count)")
                                .font(.system(size: 11, weight: .heavy))
                                .foregroundColor(Color(red: 0.23, green: 0.35, blue: 0.61))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.white.opacity(0.90))
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, 10)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(viewState.favorites) { favorite in
                                    bibleFavoriteChip(favorite)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.bottom, 6)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .background(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.92),
                        Color(red: 0.96, green: 0.97, blue: 0.99)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private func bibleFavoriteChip(_ favorite: BibleFavorite) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(favorite.reference)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(red: 0.23, green: 0.35, blue: 0.61))
                    .lineLimit(1)
                Spacer(minLength: 0)
                Button(role: .destructive) {
                    viewState.removeFavorite(favorite)
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }

            Text(favorite.verseText)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(red: 0.21, green: 0.25, blue: 0.33))
                .lineLimit(3)

            HStack(spacing: 8) {
                Button("Ir") {
                    dismissSearchFocus()
                    viewState.selectFavorite(favorite)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("Proyectar") {
                    dismissSearchFocus()
                    viewState.projectFavorite(favorite)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(12)
        .frame(width: 250, alignment: .leading)
        .background(Color.white.opacity(0.88))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var booksPanel: some View {
        BiblePanelCard(title: "Libros", subtitle: "", background: panelBackground, compactHeader: true, centeredHeader: true, showsSubtitle: false) {
            LazyVGrid(columns: bookColumns, spacing: 5) {
                ForEach(visibleBookIndexes, id: \.self) { index in
                    BibleBookTile(
                        shortTitle: viewState.bookNames[safe: index - 1] ?? "",
                        fullTitle: viewState.fullBookNames[safe: index - 1] ?? "",
                        background: bookCellBackground(for: index)
                    ) {
                        dismissSearchFocus()
                        viewState.selectBook(index)
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color(red: 0.96, green: 0.97, blue: 0.99))
        }
    }

    private var chaptersPanel: some View {
        BiblePanelCard(title: "Capítulos", subtitle: "", background: panelBackground, compactHeader: true, centeredHeader: true, showsSubtitle: false) {
            HStack(spacing: 10) {
                BiblePagingToolbar(page: $viewState.chapterPage, pageCount: chapterPageCount, showsLabel: chapterPageCount > 1)

                Spacer(minLength: 0)

                Text("Capítulo actual \(viewState.selectedChapter)")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(Color(red: 0.45, green: 0.49, blue: 0.56))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.92))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 8)

            LazyVGrid(columns: chapterColumns, spacing: 5) {
                ForEach(chapterItems, id: \.self) { item in
                    pageCell(item: item, kind: .chapter)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(chapterPanelFill)
        }
    }

    private var versesPanel: some View {
        BiblePanelCard(title: "Versículos", subtitle: "", background: panelBackground, compactHeader: true, centeredHeader: true, showsSubtitle: false) {
            HStack(spacing: 10) {
                BiblePagingToolbar(page: $viewState.versePage, pageCount: versePageCount, showsLabel: versePageCount > 1)

                Spacer(minLength: 0)

                Text("Doble clic proyecta")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(Color(red: 0.45, green: 0.49, blue: 0.56))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.92))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 8)

            LazyVGrid(columns: verseColumns, spacing: 5) {
                ForEach(verseItems, id: \.self) { item in
                    pageCell(item: item, kind: .verse)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(versePanelFill)
        }
    }

    private func verseRow(_ verse: Verse) -> some View {
        BibleVerseRow(
            verse: verse,
            isSelected: viewState.selectedVerse == verse.number,
            isProjected: viewState.isProjectedVerse(verse.number),
            onSelect: {
                dismissSearchFocus()
                viewState.selectVerse(verse.number)
            },
            onProject: {
                dismissSearchFocus()
                viewState.selectVerse(verse.number)
                viewState.projectVerse(verse.number)
            }
        )
    }

    private func pageCell(item: PageItem, kind: PageCellKind) -> some View {
        let number = item.numberValue
        let isNavigation = item.isNavigation
        let isSelected = kind == .chapter ? viewState.selectedChapter == number : viewState.selectedVerse == number
        let isProjected = kind == .verse && viewState.isProjectedVerse(number)

        return Button(action: {
            handlePageCellTap(item: item, kind: kind)
        }) {
            VStack(spacing: 2) {
                Text(item.label)
                    .font(.system(size: 14, weight: isNavigation ? .bold : .semibold))
                    .frame(maxWidth: .infinity)

                if kind == .verse, isProjected, !isNavigation {
                    Text("EN VIVO")
                        .font(.system(size: 8, weight: .heavy))
                        .tracking(0.3)
                } else if isSelected, !isNavigation {
                    Text(kind == .chapter ? "ACTIVO" : "LISTO")
                        .font(.system(size: 8, weight: .heavy))
                        .tracking(0.3)
                        .opacity(0.92)
                }
            }
            .padding(.vertical, kind == .verse ? 7 : 8)
            .frame(maxWidth: .infinity, minHeight: kind == .verse ? 42 : 40)
            .background(cellBackground(isSelected: isSelected, isProjected: isProjected, isNavigation: isNavigation, kind: kind))
            .foregroundColor(cellForeground(isSelected: isSelected, isProjected: isProjected, isNavigation: isNavigation, kind: kind))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(cellStrokeColor(isSelected: isSelected, isProjected: isProjected, isNavigation: isNavigation), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            TapGesture(count: 2).onEnded {
                guard kind == .verse, number > 0 else { return }
                viewState.selectVerse(number)
                viewState.projectVerse(number)
            }
        )
    }

    private func handlePageCellTap(item: PageItem, kind: PageCellKind) {
        dismissSearchFocus()
        switch item {
        case .number(let number):
            if kind == .chapter {
                viewState.selectChapter(number)
            } else {
                viewState.selectVerse(number)
            }
        case .next:
            if kind == .chapter {
                viewState.moveChapterPageForward()
            } else {
                viewState.moveVersePageForward()
            }
        case .prev:
            if kind == .chapter {
                viewState.moveChapterPageBackward()
            } else {
                viewState.moveVersePageBackward()
            }
        }
    }

    private var librarySheet: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Biblioteca de Biblias")
                        .font(.system(size: 24, weight: .bold))
                    Text("Administra, edita y asigna tus versiones a VERS 1, VERS 2 y VERS 3 sin reimportarlas.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button("Cerrar") {
                    showingLibrarySheet = false
                }
                .buttonStyle(.borderedProminent)
            }

            HStack(spacing: 12) {
                librarySummaryCard(title: "Cargadas", value: "\(bibleManager.library.count)/10", subtitle: "Capacidad total")
                librarySummaryCard(title: "Español", value: "\(bibleManager.library.filter { $0.language == BibleLanguageOption.spanish.rawValue }.count)", subtitle: "ES")
                librarySummaryCard(title: "Inglés", value: "\(bibleManager.library.filter { $0.language == BibleLanguageOption.english.rawValue }.count)", subtitle: "EN")
                librarySummaryCard(title: "Portugués", value: "\(bibleManager.library.filter { $0.language == BibleLanguageOption.portuguese.rawValue }.count)", subtitle: "PT")
            }

            HStack(alignment: .top, spacing: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Importar Biblia Zefania XML")
                        .font(.system(size: 19, weight: .bold))

                    VStack(spacing: 10) {
                        TextField("Nombre de la Biblia", text: $importName)
                            .textFieldStyle(.roundedBorder)

                        TextField("Alias (ej: RV1909)", text: $importAlias)
                            .textFieldStyle(.roundedBorder)

                        Picker("Idioma", selection: $importLanguage) {
                            ForEach(BibleLanguageOption.allCases) { option in
                                Text("\(option.label) (\(option.rawValue))").tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    HStack {
                        Text("Solo se permiten biblias en XML Zefania.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Importar XML") {
                            bibleManager.importBibleToLibrary(name: importName, alias: importAlias, language: importLanguage)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!bibleManager.canImportMoreBibles)
                    }
                }
                .padding(18)
                .frame(maxWidth: 320, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.94))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color(red: 0.82, green: 0.85, blue: 0.90), lineWidth: 1)
                        )
                )

                VStack(alignment: .leading, spacing: 14) {
                    Text("Biblias por idioma")
                        .font(.system(size: 19, weight: .bold))

                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            if bibleManager.library.isEmpty {
                                VStack(alignment: .center, spacing: 8) {
                                    Text("No hay biblias en la biblioteca")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(Color(red: 0.27, green: 0.31, blue: 0.39))
                                    Text("Importa una versión y luego asígnala a los slots activos.")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 36)
                            } else {
                                ForEach(BibleLanguageOption.allCases) { language in
                                    let items = bibleManager.library.filter { $0.language == language.rawValue }
                                    if !items.isEmpty {
                                        VStack(alignment: .leading, spacing: 10) {
                                            HStack {
                                                Text("\(language.label) (\(language.rawValue))")
                                                    .font(.system(size: 15, weight: .heavy))
                                                Text("\(items.count)")
                                                    .font(.system(size: 11, weight: .bold))
                                                    .foregroundColor(.secondary)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 4)
                                                    .background(Color.white.opacity(0.92))
                                                    .clipShape(Capsule())
                                            }

                                            ForEach(items) { item in
                                                bibleLibraryRow(item)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(red: 0.96, green: 0.97, blue: 0.99))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color(red: 0.82, green: 0.85, blue: 0.90), lineWidth: 1)
                        )
                )
            }

            if let error = bibleManager.lastImportError {
                Text(error)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.red)
            }
        }
        .padding(24)
        .frame(width: 860, height: 650)
        .background(Color(red: 0.94, green: 0.96, blue: 0.99))
    }

    private var editBibleSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Editar Biblia")
                .font(.system(size: 20, weight: .bold))

            TextField("Nombre", text: $editName)
                .textFieldStyle(.roundedBorder)

            TextField("Alias", text: $editAlias)
                .textFieldStyle(.roundedBorder)

            Picker("Idioma", selection: $editLanguage) {
                ForEach(BibleLanguageOption.allCases) { option in
                    Text("\(option.label) (\(option.rawValue))").tag(option)
                }
            }
            .pickerStyle(.segmented)

            HStack {
                Spacer()

                Button("Cancelar") {
                    showingEditBibleSheet = false
                }

                Button("Guardar") {
                    if let editTargetID {
                        bibleManager.updateLibraryItem(id: editTargetID, name: editName, alias: editAlias, language: editLanguage)
                    }
                    showingEditBibleSheet = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 420)
    }

    private var panelBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color(red: 0.93, green: 0.95, blue: 0.98))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(red: 0.82, green: 0.85, blue: 0.90), lineWidth: 1)
            )
    }

    private var toolbarBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(red: 0.92, green: 0.94, blue: 0.97))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color(red: 0.82, green: 0.85, blue: 0.90), lineWidth: 1)
            )
            .shadow(color: Color(red: 0.36, green: 0.42, blue: 0.52).opacity(0.08), radius: 8, x: 0, y: 3)
    }

    private var chapterPanelFill: some View {
        Group {
            if chapterNeedsPagination {
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.88),
                        Color(red: 0.93, green: 0.95, blue: 0.98)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                LinearGradient(
                    colors: [
                        colorForBook(index: viewState.selectedBookIndex).opacity(0.96),
                        colorForBook(index: viewState.selectedBookIndex).opacity(0.78)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    private var versePanelFill: some View {
        Group {
            if verseNeedsPagination {
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.88),
                        Color(red: 0.93, green: 0.95, blue: 0.98)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                LinearGradient(
                    colors: [
                        colorForBook(index: viewState.selectedBookIndex).opacity(0.96),
                        colorForBook(index: viewState.selectedBookIndex).opacity(0.78)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    private func bookCellBackground(for index: Int) -> some View {
        let base = colorForBook(index: index)
        let isSelected = viewState.selectedBookIndex == index
        return isSelected ? base : base.opacity(0.92)
    }

    @ViewBuilder
    private func bibleLibraryRow(_ item: BibleLibraryItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.displayTitle)
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(Color(red: 0.20, green: 0.24, blue: 0.30))
                    Text(item.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 0.44, green: 0.49, blue: 0.58))
                    HStack(spacing: 8) {
                        Text(item.language)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(red: 0.18, green: 0.36, blue: 0.68))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(red: 0.90, green: 0.94, blue: 1.0))
                            .clipShape(Capsule())
                        Text(item.sourceBadge ?? "BIBLIA DISPONIBLE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(red: 0.18, green: 0.36, blue: 0.68))
                    }
                }

                Spacer()

                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { slotIndex in
                        Button("V\(slotIndex + 1)") {
                            bibleManager.assignLibraryItem(item.id, toSlot: slotIndex)
                            if viewState.selectedVersionIndex == slotIndex {
                                viewState.resetSelectionForVersion()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
            }

            HStack(spacing: 10) {
                let assignedSlots = bibleManager.versions.enumerated()
                    .filter { $0.element.libraryItemID == item.id }
                    .map { "V\($0.offset + 1)" }
                Text(assignedSlots.isEmpty ? "No asignada a slots activos" : "Asignada en \(assignedSlots.joined(separator: ", "))")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color(red: 0.44, green: 0.49, blue: 0.58))

                Spacer()

                Button("Editar") {
                    editTargetID = item.id
                    editName = item.name
                    editAlias = item.alias
                    editLanguage = BibleLanguageOption(rawValue: item.language) ?? .spanish
                    showingEditBibleSheet = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("Eliminar", role: .destructive) {
                    bibleManager.deleteLibraryItem(id: item.id)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color(red: 0.82, green: 0.85, blue: 0.90), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private func librarySummaryCard(title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(red: 0.48, green: 0.53, blue: 0.61))
            Text(value)
                .font(.system(size: 19, weight: .heavy))
                .foregroundColor(Color(red: 0.18, green: 0.24, blue: 0.34))
            Text(subtitle)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.94))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color(red: 0.82, green: 0.85, blue: 0.90), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private func versionBackground(for id: Int) -> some View {
        let shouldEmphasize = displayManager.bibleProjectionSettings.emphasizesSelectedVersion
        if viewState.selectedVersionIndex == id, shouldEmphasize {
            Color(red: 0.22, green: 0.52, blue: 0.88)
        } else {
            Color(red: 0.93, green: 0.95, blue: 0.98)
        }
    }

    private func cellBackground(isSelected: Bool, isProjected: Bool, isNavigation: Bool, kind: PageCellKind) -> some View {
        Group {
            if isProjected {
                LinearGradient(
                    colors: [Color(red: 0.10, green: 0.46, blue: 0.84), Color(red: 0.06, green: 0.34, blue: 0.66)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else if isSelected {
                LinearGradient(
                    colors: [Color(red: 0.54, green: 0.64, blue: 0.80), Color(red: 0.42, green: 0.53, blue: 0.69)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else if isNavigation {
                LinearGradient(
                    colors: [Color(red: 0.50, green: 0.58, blue: 0.67), Color(red: 0.38, green: 0.46, blue: 0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else if (kind == .chapter && !chapterNeedsPagination) || (kind == .verse && !verseNeedsPagination) {
                colorForBook(index: viewState.selectedBookIndex)
            } else {
                LinearGradient(
                    colors: [Color.white, Color(red: 0.88, green: 0.91, blue: 0.95)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    private func cellForeground(isSelected: Bool, isProjected: Bool, isNavigation: Bool, kind: PageCellKind) -> Color {
        if isSelected || isProjected || isNavigation || ((kind == .chapter && !chapterNeedsPagination) || (kind == .verse && !verseNeedsPagination)) {
            return .white
        }
        return Color(red: 0.23, green: 0.27, blue: 0.33)
    }

    private func cellStrokeColor(isSelected: Bool, isProjected: Bool, isNavigation: Bool) -> Color {
        if isProjected {
            return Color.white.opacity(0.32)
        }
        if isSelected {
            return Color.white.opacity(0.26)
        }
        if isNavigation {
            return Color.white.opacity(0.22)
        }
        return Color.black.opacity(0.07)
    }

    private var selectionTitle: String {
        viewState.selectionTitle
    }

    private var currentBookTitle: String {
        viewState.currentBookTitle
    }

    private var emptyBibleMessage: String {
        viewState.emptyBibleMessage
    }

    private var currentSelectionLabel: String {
        if let verse = viewState.selectedVerse {
            return "\(viewState.selectedChapter):\(verse)"
        }
        return "\(viewState.selectedChapter)"
    }

    private func bibleStatusText(title: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(red: 0.48, green: 0.52, blue: 0.60))
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(red: 0.22, green: 0.26, blue: 0.32))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var currentVerseText: String? {
        guard let selectedVerse = viewState.selectedVerse else { return nil }
        return currentVerses.first(where: { $0.number == selectedVerse })?.text
    }

    private var selectedVersePreviewTitle: String {
        if let selectedVerse = viewState.selectedVerse {
            return "\(selectionTitle) • \(selectedVerse)"
        }
        return selectionTitle
    }

    private var selectedVerseTextPreview: String {
        currentVerseText ?? "Selecciona un versículo para verlo y proyectarlo desde este panel."
    }

    private var statusBadgeRow: some View {
        HStack(spacing: 8) {
            statusBadge(
                title: displayManager.isProjectorActive ? "En vivo" : "Sin salida",
                color: displayManager.isProjectorActive ? Color(red: 0.12, green: 0.58, blue: 0.30) : Color(red: 0.51, green: 0.55, blue: 0.62)
            )
            if currentVersion?.sourceBadge != nil, displayManager.bibleProjectionSettings.showsImportBadge {
                statusBadge(title: "Importado", color: Color(red: 0.18, green: 0.48, blue: 0.86))
            }
        }
    }

    private func statusBadge(title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color)
            .clipShape(Capsule())
    }

    private func detailLine(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(red: 0.22, green: 0.26, blue: 0.32))
        }
    }

    private func infoStrip(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(red: 0.22, green: 0.26, blue: 0.32))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.88))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func dismissSearchFocus() {
        isSearchFocused = false
    }

    private func colorForBook(index: Int) -> Color {
        switch index {
        case 1...5:   return Color(red: 0.60, green: 0.39, blue: 0.17)
        case 6...17:  return Color(red: 0.88, green: 0.58, blue: 0.14)
        case 18...22: return Color(red: 0.77, green: 0.20, blue: 0.22)
        case 23...27: return Color(red: 0.54, green: 0.33, blue: 0.67)
        case 28...39: return Color(red: 0.23, green: 0.44, blue: 0.72)
        case 40...44: return Color(red: 0.13, green: 0.61, blue: 0.71)
        case 45...53: return Color(red: 0.19, green: 0.63, blue: 0.35)
        case 54...57: return Color(red: 0.37, green: 0.70, blue: 0.43)
        case 58...66: return Color(red: 0.17, green: 0.53, blue: 0.53)
        default:      return Color.gray
        }
    }
}

private enum PageCellKind {
    case chapter
    case verse
}

private struct BiblePanelCard<Content: View, Background: View>: View {
    let title: String
    let subtitle: String
    let background: Background
    let compactHeader: Bool
    let centeredHeader: Bool
    let showsSubtitle: Bool
    @ViewBuilder let content: Content

    init(
        title: String,
        subtitle: String,
        background: Background,
        compactHeader: Bool = false,
        centeredHeader: Bool = false,
        showsSubtitle: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.background = background
        self.compactHeader = compactHeader
        self.centeredHeader = centeredHeader
        self.showsSubtitle = showsSubtitle
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if !centeredHeader {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.19, green: 0.48, blue: 0.86), Color(red: 0.11, green: 0.34, blue: 0.68)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: compactHeader ? 4 : 6, height: compactHeader ? 22 : 32)
                }

                if centeredHeader {
                    Spacer(minLength: 0)
                }

                VStack(alignment: centeredHeader ? .center : .leading, spacing: showsSubtitle ? 2 : 0) {
                    Text(title)
                        .font(.system(size: compactHeader ? 13 : 15, weight: .heavy))
                        .foregroundColor(Color(red: 0.18, green: 0.22, blue: 0.29))
                        .frame(maxWidth: .infinity, alignment: centeredHeader ? .center : .leading)

                    if showsSubtitle {
                        Text(subtitle)
                            .font(.system(size: compactHeader ? 10 : 11, weight: .medium))
                            .foregroundColor(Color(red: 0.48, green: 0.53, blue: 0.61))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: centeredHeader ? .center : .leading)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, compactHeader ? 10 : 14)
            .padding(.vertical, compactHeader ? (showsSubtitle ? 7 : 6) : 12)
            .frame(minHeight: compactHeader ? 34 : nil)
            .background(Color(red: 0.94, green: 0.96, blue: 0.99))

            Divider()
            content
        }
        .background(background)
    }
}

private struct BiblePagingToolbar: View {
    @Binding var page: Int
    let pageCount: Int
    var showsLabel: Bool = true

    var body: some View {
        HStack {
            if showsLabel {
                Text(pageCount > 1 ? "Página \(page + 1) / \(pageCount)" : "")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(red: 0.47, green: 0.52, blue: 0.60))
            }

            Spacer()

            if pageCount > 1 {
                HStack(spacing: 6) {
                    BiblePagingButton(title: "<<", isEnabled: page > 0) {
                        page -= 1
                    }
                    BiblePagingButton(title: ">>", isEnabled: page < pageCount - 1) {
                        page += 1
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, 2)
        .background(Color.white.opacity(0.58))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct BiblePagingButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 34, height: 24)
                .background(
                    isEnabled
                    ? LinearGradient(
                        colors: [Color(red: 0.35, green: 0.45, blue: 0.60), Color(red: 0.26, green: 0.34, blue: 0.48)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    : LinearGradient(
                        colors: [Color.gray.opacity(0.55), Color.gray.opacity(0.42)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

private struct BibleVersionCard<Background: View>: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let emphasizesSelection: Bool
    let background: Background
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .center, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .center)
                Text(subtitle)
                    .font(.system(size: 8, weight: .semibold))
                    .opacity(0.82)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .multilineTextAlignment(.center)
            .foregroundColor(isSelected ? .white : Color(red: 0.24, green: 0.28, blue: 0.35))
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(minWidth: 54)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(isSelected && emphasizesSelection ? Color(red: 0.13, green: 0.40, blue: 0.75) : Color.black.opacity(0.08), lineWidth: isSelected && emphasizesSelection ? 2 : 1)
            )
            .scaleEffect(isSelected && emphasizesSelection ? 1.01 : 1)
        }
        .buttonStyle(.plain)
        .focusable(false)
    }
}

private struct BibleBookTile<Background: View>: View {
    let shortTitle: String
    let fullTitle: String
    let background: Background
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text(shortTitle)
                    .font(.system(size: 13, weight: .heavy))
                Text(fullTitle)
                    .font(.system(size: 8, weight: .semibold))
                    .lineLimit(1)
                    .opacity(0.9)
            }
            .frame(maxWidth: .infinity, minHeight: 39)
            .padding(.vertical, 2)
            .background(background)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct BibleVerseRow: View {
    let verse: Verse
    let isSelected: Bool
    let isProjected: Bool
    let onSelect: () -> Void
    let onProject: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(numberBadgeColor)

                    Text("\(verse.number)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(numberTextColor)
                }
                .frame(width: 34, height: 28)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text("Versículo \(verse.number)")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundColor(Color(red: 0.46, green: 0.50, blue: 0.58))

                        if isProjected {
                            statusPill(title: "EN VIVO", color: Color(red: 0.11, green: 0.46, blue: 0.84))
                        } else if isSelected {
                            statusPill(title: "SELECCIONADO", color: Color(red: 0.36, green: 0.44, blue: 0.58))
                        }
                    }

                    Text(verse.text)
                        .font(.system(size: 15, weight: .semibold, design: .serif))
                        .foregroundColor(Color(red: 0.20, green: 0.22, blue: 0.27))
                        .multilineTextAlignment(.leading)
                        .lineLimit(4)

                    HStack(spacing: 8) {
                        Label("Clic selecciona", systemImage: "cursorarrow")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(red: 0.48, green: 0.52, blue: 0.60))

                        Label("Doble clic proyecta", systemImage: "play.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(red: 0.48, green: 0.52, blue: 0.60))
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(rowFillColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(rowStrokeColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contentTransition(.interpolate)
        .simultaneousGesture(TapGesture(count: 2).onEnded(onProject))
    }

    private var numberBadgeColor: Color {
        if isProjected {
            return Color(red: 0.10, green: 0.46, blue: 0.84)
        }
        if isSelected {
            return Color(red: 0.64, green: 0.72, blue: 0.85)
        }
        return Color(red: 0.84, green: 0.88, blue: 0.93)
    }

    private var numberTextColor: Color {
        if isProjected || isSelected {
            return .white
        }
        return Color(red: 0.20, green: 0.22, blue: 0.27)
    }

    private var rowFillColor: Color {
        if isProjected {
            return Color(red: 0.87, green: 0.93, blue: 1.00)
        }
        if isSelected {
            return Color(red: 0.92, green: 0.95, blue: 0.99)
        }
        return .white
    }

    private var rowStrokeColor: Color {
        if isProjected {
            return Color(red: 0.10, green: 0.46, blue: 0.84)
        }
        if isSelected {
            return Color(red: 0.63, green: 0.71, blue: 0.84)
        }
        return Color.black.opacity(0.06)
    }

    private func statusPill(title: String, color: Color) -> some View {
        Text(title)
            .font(.system(size: 9, weight: .heavy))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .clipShape(Capsule())
    }
}

private extension PageItem {
    var numberValue: Int {
        if case .number(let value) = self {
            return value
        }
        return -1
    }

    var label: String {
        switch self {
        case .number(let value):
            return "\(value)"
        case .next:
            return ">>"
        case .prev:
            return "<<"
        }
    }

    var isNavigation: Bool {
        switch self {
        case .next, .prev:
            return true
        case .number:
            return false
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

import SwiftUI

struct ConsoleAdaptiveText: View {
    let text: String
    let style: ConsoleAdaptiveTextStyle
    let font: Font
    let color: Color
    let lineLimit: Int
    var alignment: TextAlignment = .leading

    @State private var availableWidth: CGFloat = 0

    var body: some View {
        Text(resolvedText)
            .font(font)
            .foregroundStyle(color)
            .lineLimit(lineLimit)
            .multilineTextAlignment(alignment)
            .background(
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            availableWidth = proxy.size.width
                        }
                        .onChange(of: proxy.size.width) { _, newWidth in
                            availableWidth = newWidth
                        }
                }
            )
    }

    private var resolvedText: String {
        text.consoleAdapted(for: availableWidth, style: style)
    }
}

enum ConsoleAdaptiveTextStyle {
    case title
    case chip
    case reference
    case compactLabel
    case fileName
    case generic
}

private extension String {
    func consoleAdapted(for width: CGFloat, style: ConsoleAdaptiveTextStyle) -> String {
        let safeWidth = max(width, 0)

        switch style {
        case .title:
            if safeWidth >= 280 { return self }
            if safeWidth >= 200 { return condenseMiddle(prefixCount: 22, suffixCount: 14) }
            if safeWidth >= 140 { return condenseMiddle(prefixCount: 16, suffixCount: 10) }
            return condenseMiddle(prefixCount: 10, suffixCount: 7)

        case .chip:
            if safeWidth >= 170 { return self }
            if safeWidth >= 120 { return condenseMiddle(prefixCount: 14, suffixCount: 9) }
            return condenseMiddle(prefixCount: 9, suffixCount: 6)

        case .reference:
            if safeWidth >= 220 { return self }
            if safeWidth >= 150 { return condenseMiddle(prefixCount: 16, suffixCount: 10) }
            return condenseMiddle(prefixCount: 10, suffixCount: 7)

        case .compactLabel:
            if safeWidth >= 120 { return self }
            if safeWidth >= 84 { return condenseMiddle(prefixCount: 8, suffixCount: 5) }
            return condenseMiddle(prefixCount: 5, suffixCount: 4)

        case .fileName:
            let fileURL = URL(fileURLWithPath: self)
            let baseName = fileURL.deletingPathExtension().lastPathComponent
            let fileExtension = fileURL.pathExtension

            if safeWidth >= 220 { return self }
            let condensedBase: String
            if safeWidth >= 160 {
                condensedBase = baseName.condenseMiddle(prefixCount: 16, suffixCount: 10)
            } else if safeWidth >= 110 {
                condensedBase = baseName.condenseMiddle(prefixCount: 11, suffixCount: 7)
            } else {
                condensedBase = baseName.condenseMiddle(prefixCount: 8, suffixCount: 5)
            }

            return fileExtension.isEmpty ? condensedBase : "\(condensedBase).\(fileExtension)"

        case .generic:
            if safeWidth >= 220 { return self }
            if safeWidth >= 160 { return condenseMiddle(prefixCount: 16, suffixCount: 10) }
            return condenseMiddle(prefixCount: 11, suffixCount: 7)
        }
    }

    func condenseMiddle(prefixCount: Int, suffixCount: Int) -> String {
        guard count > prefixCount + suffixCount + 3 else { return self }

        let startIndex = index(self.startIndex, offsetBy: prefixCount)
        let endIndex = index(self.endIndex, offsetBy: -suffixCount)
        let prefix = self[self.startIndex..<startIndex]
        let suffix = self[endIndex..<self.endIndex]
        return "\(prefix)...\(suffix)"
    }
}

import SwiftUI

struct PresentationAdaptiveText: View {
    let text: String
    let style: PresentationAdaptiveTextStyle
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
        text.presentationAdapted(for: availableWidth, style: style)
    }
}

enum PresentationAdaptiveTextStyle {
    case documentTitle
    case fileName
    case chip
    case reference
    case generic
}

private extension String {
    func presentationAdapted(for width: CGFloat, style: PresentationAdaptiveTextStyle) -> String {
        let safeWidth = max(width, 0)
        switch style {
        case .documentTitle:
            if safeWidth >= 260 { return self }
            if safeWidth >= 200 { return condenseMiddle(prefixCount: 28, suffixCount: 16) }
            if safeWidth >= 150 { return condenseMiddle(prefixCount: 20, suffixCount: 12) }
            return condenseMiddle(prefixCount: 14, suffixCount: 8)

        case .fileName:
            let fileURL = URL(fileURLWithPath: self)
            let baseName = fileURL.deletingPathExtension().lastPathComponent
            let fileExtension = fileURL.pathExtension
            if safeWidth >= 220 { return self }
            if safeWidth >= 170 {
                return fileExtension.isEmpty
                    ? baseName.condenseMiddle(prefixCount: 20, suffixCount: 12)
                    : "\(baseName.condenseMiddle(prefixCount: 20, suffixCount: 12)).\(fileExtension)"
            }
            if safeWidth >= 130 {
                return fileExtension.isEmpty
                    ? baseName.condenseMiddle(prefixCount: 14, suffixCount: 10)
                    : "\(baseName.condenseMiddle(prefixCount: 14, suffixCount: 10)).\(fileExtension)"
            }
            return fileExtension.isEmpty
                ? baseName.condenseMiddle(prefixCount: 10, suffixCount: 7)
                : "\(baseName.condenseMiddle(prefixCount: 10, suffixCount: 7)).\(fileExtension)"

        case .chip:
            if safeWidth >= 180 { return self }
            if safeWidth >= 120 { return condenseMiddle(prefixCount: 14, suffixCount: 10) }
            return condenseMiddle(prefixCount: 9, suffixCount: 7)

        case .reference:
            if safeWidth >= 140 { return self }
            if safeWidth >= 96 { return condenseMiddle(prefixCount: 10, suffixCount: 8) }
            return condenseMiddle(prefixCount: 7, suffixCount: 5)

        case .generic:
            if safeWidth >= 220 { return self }
            if safeWidth >= 160 { return condenseMiddle(prefixCount: 18, suffixCount: 12) }
            return condenseMiddle(prefixCount: 12, suffixCount: 8)
        }
    }

    func condenseMiddle(prefixCount: Int, suffixCount: Int) -> String {
        guard count > prefixCount + suffixCount + 3 else { return self }

        let startIndex = index(startIndex, offsetBy: prefixCount)
        let endIndex = index(endIndex, offsetBy: -suffixCount)
        let prefix = self[self.startIndex..<startIndex]
        let suffix = self[endIndex..<self.endIndex]
        return "\(prefix)...\(suffix)"
    }
}

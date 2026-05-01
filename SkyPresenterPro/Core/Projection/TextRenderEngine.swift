import AppKit
import SwiftUI

struct TextRenderInput: Equatable {
    var title: String?
    var lines: [String]
    var comment: String?
    var reference: String?
    var theme: ProjectionTheme
    var renderScale: CGFloat
}

struct TextRenderLayout: Equatable {
    var title: TextRenderBlock?
    var lines: [TextRenderBlock]
    var comment: TextRenderBlock?
    var reference: TextRenderBlock?
    var horizontalAlignment: HorizontalAlignment
    var frameAlignment: Alignment
    var maxWidthFraction: CGFloat
    var verticalOffset: CGFloat
    var spacing: CGFloat
    var margin: CGFloat
    var textBoxMode: ProjectionTextBoxMode
}

struct TextRenderBlock: Identifiable, Equatable {
    enum Role: Equatable {
        case title
        case main
        case comment
        case reference
    }

    let id = UUID()
    var role: Role
    var text: String
    var font: Font
    var color: Color
    var alignment: TextAlignment
    var scaleFactor: CGFloat
    var box: TextRenderBox?
    var shadow: TextRenderShadow?
    var glow: TextRenderGlow?
    var tracking: CGFloat
}

struct TextRenderBox: Equatable {
    var color: Color
    var opacity: Double
    var horizontalPadding: CGFloat
    var verticalPadding: CGFloat
    var cornerRadius: CGFloat
}

struct TextRenderShadow: Equatable {
    var color: Color
    var radius: CGFloat
    var x: CGFloat
    var y: CGFloat
}

struct TextRenderGlow: Equatable {
    var color: Color
    var radius: CGFloat
}

enum TextRenderEngine {
    static func layout(input: TextRenderInput) -> TextRenderLayout {
        let theme = input.theme
        let renderScale = input.renderScale
        let mainFontSize = max(20, theme.fontSize * renderScale)
        let titleFontSize = max(26, theme.fontSize * 1.4 * renderScale)
        let commentFontSize = max(12, theme.commentFontSize * renderScale)
        let referenceFontSize = max(12, theme.referenceFontSize * renderScale)

        let title = input.title.map {
            block(
                role: .title,
                text: normalized($0, uppercase: theme.uppercaseEnabled),
                fontFamily: theme.fontFamily,
                size: titleFontSize,
                weight: theme.fontWeight,
                italic: theme.italic,
                color: theme.textColor,
                theme: theme,
                scaleFactor: 0.65,
                boxed: theme.textBoxMode == .global
            )
        }

        let lines = input.lines.map {
            block(
                role: .main,
                text: normalized($0, uppercase: theme.uppercaseEnabled),
                fontFamily: theme.fontFamily,
                size: mainFontSize,
                weight: theme.fontWeight,
                italic: theme.italic,
                color: theme.textColor,
                theme: theme,
                scaleFactor: 0.55,
                boxed: theme.textBoxMode == .perLine
            )
        }

        let comment = input.comment.flatMap { rawComment -> TextRenderBlock? in
            guard theme.commentVisible, !rawComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            return block(
                role: .comment,
                text: rawComment,
                fontFamily: theme.commentFontFamily,
                size: commentFontSize,
                weight: theme.commentBold ? .bold : .regular,
                italic: theme.commentItalic,
                color: theme.commentColor,
                theme: theme,
                scaleFactor: 0.72,
                boxed: false
            )
        }

        let reference = input.reference.flatMap { rawReference -> TextRenderBlock? in
            guard theme.showReference, !rawReference.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            var referenceBlock = block(
                role: .reference,
                text: rawReference,
                fontFamily: theme.referenceFontFamily,
                size: referenceFontSize,
                weight: .medium,
                italic: false,
                color: theme.referenceColor,
                theme: theme,
                scaleFactor: 0.75,
                boxed: false
            )
            if theme.referenceBoxEnabled {
                referenceBlock.box = TextRenderBox(
                    color: theme.referenceBoxColor,
                    opacity: theme.referenceBoxOpacity,
                    horizontalPadding: theme.textBoxHorizontalPadding * 0.75,
                    verticalPadding: theme.textBoxVerticalPadding * 0.75,
                    cornerRadius: theme.textBoxCornerRadius
                )
            }
            return referenceBlock
        }

        return TextRenderLayout(
            title: title,
            lines: lines,
            comment: comment,
            reference: reference,
            horizontalAlignment: theme.textHorizontalAlignment,
            frameAlignment: theme.verticalFrameAlignment,
            maxWidthFraction: min(max(theme.maxTextWidth, 0.35), 1.0),
            verticalOffset: theme.verticalOffset * renderScale,
            spacing: max(6, theme.lineSpacing * renderScale),
            margin: max(16, theme.textMargin * renderScale),
            textBoxMode: theme.textBoxMode
        )
    }

    private static func block(
        role: TextRenderBlock.Role,
        text: String,
        fontFamily: String?,
        size: CGFloat,
        weight: Font.Weight,
        italic: Bool,
        color: Color,
        theme: ProjectionTheme,
        scaleFactor: CGFloat,
        boxed: Bool
    ) -> TextRenderBlock {
        let baseFont: Font = {
            if let fontFamily, !fontFamily.isEmpty {
                let font = Font.custom(fontFamily, size: size)
                return italic ? font.italic() : font
            }
            let font = Font.system(size: size, weight: weight)
            return italic ? font.italic() : font
        }()

        return TextRenderBlock(
            role: role,
            text: text,
            font: baseFont,
            color: color,
            alignment: theme.textAlignment,
            scaleFactor: scaleFactor,
            box: boxed ? TextRenderBox(
                color: theme.textBoxColor,
                opacity: theme.textBoxOpacity,
                horizontalPadding: theme.textBoxHorizontalPadding,
                verticalPadding: theme.textBoxVerticalPadding,
                cornerRadius: theme.textBoxCornerRadius
            ) : nil,
            shadow: theme.shadowEnabled ? TextRenderShadow(
                color: theme.shadowColor,
                radius: theme.shadowRadius,
                x: theme.shadowX,
                y: theme.shadowY
            ) : nil,
            glow: theme.glowEnabled ? TextRenderGlow(
                color: color.opacity(0.5),
                radius: theme.glowRadius
            ) : nil,
            tracking: theme.characterSpacing
        )
    }

    private static func normalized(_ text: String, uppercase: Bool) -> String {
        uppercase ? text.uppercased() : text
    }
}

struct TextRenderEngineView: View {
    let layout: TextRenderLayout

    var body: some View {
        VStack(alignment: layout.horizontalAlignment, spacing: layout.spacing) {
            if let reference = layout.reference, referenceFirst {
                blockView(reference)
            }

            if let title = layout.title {
                blockView(title)
            }

            if layout.textBoxMode == .global {
                VStack(alignment: layout.horizontalAlignment, spacing: max(4, layout.spacing * 0.46)) {
                    ForEach(layout.lines) { block in
                        textOnly(block)
                    }
                }
                .padding(.horizontal, layout.lines.first?.box?.horizontalPadding ?? 0)
                .padding(.vertical, layout.lines.first?.box?.verticalPadding ?? 0)
                .background(globalBoxBackground)
            } else {
                VStack(alignment: layout.horizontalAlignment, spacing: max(4, layout.spacing * 0.46)) {
                    ForEach(layout.lines) { block in
                        blockView(block)
                    }
                }
            }

            if let comment = layout.comment {
                blockView(comment)
            }

            if let reference = layout.reference, !referenceFirst {
                blockView(reference)
            }
        }
        .padding(layout.margin)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: layout.frameAlignment)
        .offset(y: layout.verticalOffset)
    }

    private var referenceFirst: Bool {
        if case .reference = layout.reference?.role {
            return false
        }
        return false
    }

    @ViewBuilder
    private var globalBoxBackground: some View {
        if let box = layout.lines.first?.box {
            RoundedRectangle(cornerRadius: box.cornerRadius, style: .continuous)
                .fill(box.color.opacity(box.opacity))
        }
    }

    private func blockView(_ block: TextRenderBlock) -> some View {
        textOnly(block)
            .padding(.horizontal, block.box?.horizontalPadding ?? 0)
            .padding(.vertical, block.box?.verticalPadding ?? 0)
            .background {
                if let box = block.box {
                    RoundedRectangle(cornerRadius: box.cornerRadius, style: .continuous)
                        .fill(box.color.opacity(box.opacity))
                }
            }
            .frame(maxWidth: .infinity, alignment: frameAlignment(for: block.alignment))
    }

    private func textOnly(_ block: TextRenderBlock) -> some View {
        Text(block.text)
            .font(block.font)
            .tracking(block.tracking)
            .foregroundStyle(block.color)
            .multilineTextAlignment(block.alignment)
            .minimumScaleFactor(block.scaleFactor)
            .shadow(
                color: block.shadow?.color ?? .clear,
                radius: block.shadow?.radius ?? 0,
                x: block.shadow?.x ?? 0,
                y: block.shadow?.y ?? 0
            )
            .shadow(
                color: block.glow?.color ?? .clear,
                radius: block.glow?.radius ?? 0
            )
            .fixedSize(horizontal: false, vertical: true)
    }

    private func frameAlignment(for alignment: TextAlignment) -> Alignment {
        switch alignment {
        case .leading: return .leading
        case .center: return .center
        case .trailing: return .trailing
        }
    }
}

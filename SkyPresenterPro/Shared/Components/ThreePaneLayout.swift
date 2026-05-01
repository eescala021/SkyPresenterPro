import SwiftUI

struct ThreePaneLayout<Leading: View, Center: View, Trailing: View>: View {
    let leadingWidth: CGFloat
    let trailingWidth: CGFloat
    @ViewBuilder let leading: () -> Leading
    @ViewBuilder let center: () -> Center
    @ViewBuilder let trailing: () -> Trailing

    @State private var currentLeadingWidth: CGFloat?
    @State private var currentTrailingWidth: CGFloat?

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            leading()
                .frame(width: resolvedLeadingWidth)
                .frame(maxHeight: .infinity, alignment: .top)

            dragHandle(isLeading: true)

            center()
                .frame(maxWidth: .infinity)
                .frame(maxHeight: .infinity, alignment: .top)

            dragHandle(isLeading: false)

            trailing()
                .frame(width: resolvedTrailingWidth)
                .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            currentLeadingWidth = leadingWidth
            currentTrailingWidth = trailingWidth
        }
    }

    private var resolvedLeadingWidth: CGFloat {
        max(220, currentLeadingWidth ?? leadingWidth)
    }

    private var resolvedTrailingWidth: CGFloat {
        max(240, currentTrailingWidth ?? trailingWidth)
    }

    private func dragHandle(isLeading: Bool) -> some View {
        Rectangle()
            .fill(Color.black.opacity(0.08))
            .frame(width: 6)
            .overlay(
                Capsule()
                    .fill(Color.black.opacity(0.16))
                    .frame(width: 3, height: 48)
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if isLeading {
                            currentLeadingWidth = max(220, resolvedLeadingWidth + value.translation.width)
                        } else {
                            currentTrailingWidth = max(240, resolvedTrailingWidth - value.translation.width)
                        }
                    }
            )
            .clipShape(Capsule())
    }
}

import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct DiagnosisSwipeRow<Content: View>: View {
    let actions: [DiagnosisSwipeAction]
    @ViewBuilder let content: () -> Content

    @State private var offset: CGFloat = 0
    @State private var isSwiping = false
    @State private var gestureStartOffset: CGFloat = 0

    private var actionWidth: CGFloat {
        CGFloat(actions.count) * 72
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            HStack(spacing: 8) {
                ForEach(actions) { action in
                    Button {
                        withAnimation(.spring(response: 0.22, dampingFraction: 0.9)) {
                            offset = 0
                            gestureStartOffset = 0
                            isSwiping = false
                        }
                        action.action()
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: action.icon)
                                .font(.headline.weight(.bold))

                            Text(localizedAppString(action.title))
                                .font(.caption2.weight(.bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                        }
                        .foregroundStyle(.white)
                        .frame(width: 64, height: 62)
                        .background(action.tint)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.trailing, 4)
            .opacity(offset == 0 ? 0 : 1)
            .allowsHitTesting(offset != 0)
            .zIndex(2)

            content()
                .offset(x: offset)
                .disabled(isSwiping || offset != 0)
                .highPriorityGesture(
                    DragGesture(minimumDistance: 18)
                        .onChanged { value in
                            let horizontal = value.translation.width
                            guard abs(horizontal) > abs(value.translation.height) else { return }

                            if !isSwiping {
                                isSwiping = true
                                gestureStartOffset = offset
                            }

                            let proposedOffset = gestureStartOffset + horizontal
                            offset = min(0, max(-actionWidth, proposedOffset))
                        }
                        .onEnded { value in
                            let predictedOffset = gestureStartOffset + value.predictedEndTranslation.width
                            let shouldOpen = predictedOffset < -(actionWidth * 0.38)
                            withAnimation(.spring(response: 0.24, dampingFraction: 0.86)) {
                                offset = shouldOpen ? -actionWidth : 0
                            }

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                                isSwiping = false
                                gestureStartOffset = offset
                            }
                        }
                )
                .zIndex(1)
        }
        .contentShape(Rectangle())
    }
}


import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct MoodValenceSlider: View {
    @Binding var value: Int
    let tint: Color

    private let barWidth: CGFloat = 46
    private let barHeight: CGFloat = 360

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .trailing, spacing: 0) {
                ForEach(MoodValence.all.reversed()) { mood in
                    Text(LocalizedStringKey(mood.title))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(value == mood.id ? AppTheme.text : .secondary)
                        .frame(height: barHeight / 7, alignment: .center)
                }
            }

            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.84, green: 0.42, blue: 0.56),
                                Color(red: 0.96, green: 0.74, blue: 0.48),
                                Color(red: 0.91, green: 0.91, blue: 0.78),
                                Color(red: 0.52, green: 0.78, blue: 0.63)
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: barWidth, height: barHeight)

                Circle()
                    .fill(.white)
                    .frame(width: 54, height: 54)
                    .shadow(color: Color.black.opacity(0.16), radius: 10, x: 0, y: 5)
                    .overlay {
                        Circle()
                            .stroke(tint, lineWidth: 4)
                    }
                    .offset(y: thumbOffset)
            }
            .frame(width: 74, height: barHeight)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        updateValue(from: gesture.location.y)
                    }
            )
        }
        .frame(maxWidth: .infinity)
    }

    private var thumbOffset: CGFloat {
        let segment = barHeight / 6
        let bottomOffset = CGFloat(value - 1) * segment
        return -bottomOffset
    }

    private func updateValue(from yLocation: CGFloat) {
        let clampedY = min(max(yLocation, 0), barHeight)
        let relativeFromBottom = 1 - (clampedY / barHeight)
        let newValue = Int((relativeFromBottom * 6).rounded()) + 1
        value = min(max(newValue, 1), 7)
    }
}


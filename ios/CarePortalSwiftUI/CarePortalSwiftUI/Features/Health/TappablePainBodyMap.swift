import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct TappablePainBodyMap: View {
    let side: PainBodySide
    @Binding var painPoints: [PainPoint]
    let tint: Color

    private var visiblePoints: [PainPoint] {
        painPoints.filter { $0.side == side }
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(LocalizedStringKey(side.rawValue))
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            GeometryReader { proxy in
                ZStack {
                    PainLocationBodyImage(side: side)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                    ForEach(visiblePoints) { point in
                        Circle()
                            .fill(tint)
                            .frame(width: 14, height: 14)
                            .overlay {
                                Circle()
                                    .stroke(.white, lineWidth: 3)
                            }
                            .shadow(color: tint.opacity(0.35), radius: 5, x: 0, y: 2)
                            .position(
                                x: proxy.size.width * point.x,
                                y: proxy.size.height * point.y
                            )
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    SpatialTapGesture()
                        .onEnded { value in
                            let normalizedX = min(max(value.location.x / proxy.size.width, 0), 1)
                            let normalizedY = min(max(value.location.y / proxy.size.height, 0), 1)

                            if let tappedPoint = visiblePoints.first(where: { point in
                                abs(point.x - normalizedX) <= 0.045 && abs(point.y - normalizedY) <= 0.045
                            }) {
                                withAnimation(.spring(response: 0.24, dampingFraction: 0.74)) {
                                    painPoints.removeAll { $0.id == tappedPoint.id }
                                }
                                return
                            }

                            guard isBodyPixel(at: value.location, in: proxy.size) else { return }
                            guard painPoints.count < 5 else { return }

                            withAnimation(.spring(response: 0.24, dampingFraction: 0.74)) {
                                painPoints.append(PainPoint(side: side, x: normalizedX, y: normalizedY))
                            }
                        }
                )
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: localizedAppString("%@ body pain map"), localizedAppString(side.rawValue)))
    }

    private func imageFrame(in size: CGSize) -> CGRect {
        let aspectRatio = PainLocationBodyImageStore.aspectRatio(for: side)
        let width = min(size.width, size.height * aspectRatio)
        let height = width / aspectRatio
        return CGRect(
            x: (size.width - width) / 2,
            y: (size.height - height) / 2,
            width: width,
            height: height
        )
    }

    private func isBodyPixel(at location: CGPoint, in size: CGSize) -> Bool {
        let frame = imageFrame(in: size)
        guard frame.contains(location), frame.width > 0, frame.height > 0 else {
            return false
        }

        let imageX = (location.x - frame.minX) / frame.width
        let imageY = (location.y - frame.minY) / frame.height
        return PainLocationBodyImageStore.containsBodyPixel(side: side, x: imageX, y: imageY)
    }
}


import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct PainBodySilhouette: View {
    let side: PainBodySide
    let tint: Color

    private let fill = Color(red: 1.00, green: 0.87, blue: 0.90)

    var body: some View {
        GeometryReader { proxy in
            let drawingRect = centeredRect(in: proxy.size)

            ZStack {
                bodyPath(in: drawingRect)
                    .fill(fill)

                bodyPath(in: drawingRect)
                    .stroke(tint.opacity(0.42), style: StrokeStyle(lineWidth: 2.3, lineCap: .round, lineJoin: .round))

                detailPath(in: drawingRect)
                    .stroke(tint.opacity(0.38), style: StrokeStyle(lineWidth: 1.7, lineCap: .round, lineJoin: .round))
            }
        }
    }

    private func centeredRect(in size: CGSize) -> CGRect {
        let width = min(size.width, size.height * 0.52)
        let height = min(size.height, width / 0.52)
        return CGRect(
            x: (size.width - width) / 2,
            y: (size.height - height) / 2,
            width: width,
            height: height
        )
    }

    private func point(_ x: CGFloat, _ y: CGFloat, in rect: CGRect) -> CGPoint {
        CGPoint(x: rect.minX + (rect.width * x), y: rect.minY + (rect.height * y))
    }

    private func bodyPath(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: point(0.50, 0.03, in: rect))
        path.addCurve(to: point(0.36, 0.16, in: rect), control1: point(0.41, 0.03, in: rect), control2: point(0.35, 0.08, in: rect))
        path.addCurve(to: point(0.42, 0.25, in: rect), control1: point(0.36, 0.20, in: rect), control2: point(0.38, 0.23, in: rect))
        path.addLine(to: point(0.39, 0.31, in: rect))
        path.addLine(to: point(0.27, 0.33, in: rect))
        path.addCurve(to: point(0.20, 0.45, in: rect), control1: point(0.22, 0.34, in: rect), control2: point(0.19, 0.38, in: rect))
        path.addCurve(to: point(0.16, 0.65, in: rect), control1: point(0.20, 0.51, in: rect), control2: point(0.16, 0.57, in: rect))
        path.addCurve(to: point(0.07, 0.77, in: rect), control1: point(0.14, 0.71, in: rect), control2: point(0.09, 0.75, in: rect))
        path.addCurve(to: point(0.03, 0.81, in: rect), control1: point(0.03, 0.79, in: rect), control2: point(0.02, 0.81, in: rect))
        path.addCurve(to: point(0.12, 0.81, in: rect), control1: point(0.05, 0.85, in: rect), control2: point(0.09, 0.84, in: rect))
        path.addCurve(to: point(0.16, 0.76, in: rect), control1: point(0.11, 0.86, in: rect), control2: point(0.16, 0.86, in: rect))
        path.addCurve(to: point(0.24, 0.61, in: rect), control1: point(0.18, 0.70, in: rect), control2: point(0.23, 0.66, in: rect))
        path.addCurve(to: point(0.32, 0.47, in: rect), control1: point(0.25, 0.55, in: rect), control2: point(0.31, 0.51, in: rect))
        path.addCurve(to: point(0.34, 0.70, in: rect), control1: point(0.36, 0.55, in: rect), control2: point(0.36, 0.63, in: rect))
        path.addCurve(to: point(0.38, 0.95, in: rect), control1: point(0.34, 0.78, in: rect), control2: point(0.34, 0.88, in: rect))
        path.addCurve(to: point(0.49, 0.96, in: rect), control1: point(0.42, 0.99, in: rect), control2: point(0.47, 0.98, in: rect))
        path.addCurve(to: point(0.50, 0.74, in: rect), control1: point(0.48, 0.87, in: rect), control2: point(0.49, 0.80, in: rect))
        path.addCurve(to: point(0.51, 0.96, in: rect), control1: point(0.51, 0.80, in: rect), control2: point(0.52, 0.87, in: rect))
        path.addCurve(to: point(0.62, 0.95, in: rect), control1: point(0.53, 0.98, in: rect), control2: point(0.58, 0.99, in: rect))
        path.addCurve(to: point(0.66, 0.70, in: rect), control1: point(0.66, 0.88, in: rect), control2: point(0.66, 0.78, in: rect))
        path.addCurve(to: point(0.68, 0.47, in: rect), control1: point(0.64, 0.63, in: rect), control2: point(0.64, 0.55, in: rect))
        path.addCurve(to: point(0.76, 0.61, in: rect), control1: point(0.69, 0.51, in: rect), control2: point(0.75, 0.55, in: rect))
        path.addCurve(to: point(0.84, 0.76, in: rect), control1: point(0.77, 0.66, in: rect), control2: point(0.82, 0.70, in: rect))
        path.addCurve(to: point(0.88, 0.81, in: rect), control1: point(0.84, 0.86, in: rect), control2: point(0.89, 0.86, in: rect))
        path.addCurve(to: point(0.97, 0.81, in: rect), control1: point(0.91, 0.84, in: rect), control2: point(0.95, 0.85, in: rect))
        path.addCurve(to: point(0.93, 0.77, in: rect), control1: point(0.98, 0.81, in: rect), control2: point(0.97, 0.79, in: rect))
        path.addCurve(to: point(0.84, 0.65, in: rect), control1: point(0.91, 0.75, in: rect), control2: point(0.86, 0.71, in: rect))
        path.addCurve(to: point(0.80, 0.45, in: rect), control1: point(0.84, 0.57, in: rect), control2: point(0.80, 0.51, in: rect))
        path.addCurve(to: point(0.73, 0.33, in: rect), control1: point(0.81, 0.38, in: rect), control2: point(0.78, 0.34, in: rect))
        path.addLine(to: point(0.61, 0.31, in: rect))
        path.addLine(to: point(0.58, 0.25, in: rect))
        path.addCurve(to: point(0.64, 0.16, in: rect), control1: point(0.62, 0.23, in: rect), control2: point(0.64, 0.20, in: rect))
        path.addCurve(to: point(0.50, 0.03, in: rect), control1: point(0.65, 0.08, in: rect), control2: point(0.59, 0.03, in: rect))
        path.closeSubpath()

        return path
    }

    private func detailPath(in rect: CGRect) -> Path {
        var path = Path()

        if side == .front {
            path.move(to: point(0.32, 0.45, in: rect))
            path.addQuadCurve(to: point(0.46, 0.45, in: rect), control: point(0.39, 0.51, in: rect))
            path.move(to: point(0.54, 0.45, in: rect))
            path.addQuadCurve(to: point(0.68, 0.45, in: rect), control: point(0.61, 0.51, in: rect))
            path.move(to: point(0.50, 0.56, in: rect))
            path.addQuadCurve(to: point(0.50, 0.57, in: rect), control: point(0.49, 0.57, in: rect))
            path.move(to: point(0.40, 0.74, in: rect))
            path.addQuadCurve(to: point(0.46, 0.73, in: rect), control: point(0.43, 0.77, in: rect))
            path.move(to: point(0.60, 0.74, in: rect))
            path.addQuadCurve(to: point(0.54, 0.73, in: rect), control: point(0.57, 0.77, in: rect))
            path.move(to: point(0.42, 0.88, in: rect))
            path.addQuadCurve(to: point(0.35, 0.88, in: rect), control: point(0.38, 0.86, in: rect))
            path.move(to: point(0.58, 0.88, in: rect))
            path.addQuadCurve(to: point(0.65, 0.88, in: rect), control: point(0.62, 0.86, in: rect))
        } else {
            path.move(to: point(0.50, 0.31, in: rect))
            path.addLine(to: point(0.50, 0.63, in: rect))
            path.move(to: point(0.35, 0.43, in: rect))
            path.addQuadCurve(to: point(0.45, 0.35, in: rect), control: point(0.44, 0.44, in: rect))
            path.move(to: point(0.65, 0.43, in: rect))
            path.addQuadCurve(to: point(0.55, 0.35, in: rect), control: point(0.56, 0.44, in: rect))
            path.move(to: point(0.36, 0.72, in: rect))
            path.addQuadCurve(to: point(0.49, 0.71, in: rect), control: point(0.42, 0.76, in: rect))
            path.move(to: point(0.64, 0.72, in: rect))
            path.addQuadCurve(to: point(0.51, 0.71, in: rect), control: point(0.58, 0.76, in: rect))
            path.move(to: point(0.42, 0.88, in: rect))
            path.addQuadCurve(to: point(0.35, 0.88, in: rect), control: point(0.38, 0.86, in: rect))
            path.move(to: point(0.58, 0.88, in: rect))
            path.addQuadCurve(to: point(0.65, 0.88, in: rect), control: point(0.62, 0.86, in: rect))
        }

        return path
    }
}


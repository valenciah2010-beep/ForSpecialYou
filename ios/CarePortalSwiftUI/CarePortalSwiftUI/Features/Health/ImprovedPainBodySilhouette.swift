import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

struct ImprovedPainBodySilhouette: View {
    let side: PainBodySide
    let tint: Color

    private let fill = Color(red: 1.00, green: 0.78, blue: 0.84)

    var body: some View {
        GeometryReader { proxy in
            let rect = bodyRect(in: proxy.size)

            ZStack {
                RoundedRectangle(cornerRadius: rect.width * 0.08, style: .continuous)
                    .fill(fill)
                    .frame(width: rect.width * 0.17, height: rect.height * 0.42)
                    .position(x: rect.minX + rect.width * 0.37, y: rect.minY + rect.height * 0.76)

                RoundedRectangle(cornerRadius: rect.width * 0.08, style: .continuous)
                    .fill(fill)
                    .frame(width: rect.width * 0.17, height: rect.height * 0.42)
                    .position(x: rect.minX + rect.width * 0.63, y: rect.minY + rect.height * 0.76)

                RoundedRectangle(cornerRadius: rect.width * 0.08, style: .continuous)
                    .fill(fill)
                    .frame(width: rect.width * 0.12, height: rect.height * 0.39)
                    .position(x: rect.minX + rect.width * 0.15, y: rect.minY + rect.height * 0.47)

                RoundedRectangle(cornerRadius: rect.width * 0.08, style: .continuous)
                    .fill(fill)
                    .frame(width: rect.width * 0.12, height: rect.height * 0.39)
                    .position(x: rect.minX + rect.width * 0.85, y: rect.minY + rect.height * 0.47)

                RoundedRectangle(cornerRadius: rect.width * 0.15, style: .continuous)
                    .fill(fill)
                    .frame(width: rect.width * 0.56, height: rect.height * 0.47)
                    .position(x: rect.midX, y: rect.minY + rect.height * 0.43)

                RoundedRectangle(cornerRadius: rect.width * 0.09, style: .continuous)
                    .fill(fill)
                    .frame(width: rect.width * 0.20, height: rect.height * 0.22)
                    .position(x: rect.midX, y: rect.minY + rect.height * 0.24)

                Circle()
                    .fill(fill)
                    .frame(width: rect.width * 0.33, height: rect.width * 0.33)
                    .position(x: rect.midX, y: rect.minY + rect.height * 0.09)
            }
        }
    }

    private func bodyRect(in size: CGSize) -> CGRect {
        let width = min(size.width * 0.72, size.height * 0.42)
        let height = min(size.height * 0.98, width / 0.42)
        return CGRect(
            x: (size.width - width) / 2,
            y: (size.height - height) / 2,
            width: width,
            height: height
        )
    }

    private func p(_ x: CGFloat, _ y: CGFloat, _ rect: CGRect) -> CGPoint {
        CGPoint(x: rect.minX + rect.width * x, y: rect.minY + rect.height * y)
    }

    private func humanSilhouettePath(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: p(0.50, 0.03, rect))
        path.addCurve(to: p(0.39, 0.06, rect), control1: p(0.45, 0.03, rect), control2: p(0.41, 0.04, rect))
        path.addCurve(to: p(0.36, 0.15, rect), control1: p(0.36, 0.09, rect), control2: p(0.35, 0.12, rect))
        path.addCurve(to: p(0.38, 0.22, rect), control1: p(0.36, 0.18, rect), control2: p(0.37, 0.20, rect))
        path.addCurve(to: p(0.42, 0.24, rect), control1: p(0.39, 0.23, rect), control2: p(0.40, 0.24, rect))
        path.addLine(to: p(0.41, 0.28, rect))
        path.addCurve(to: p(0.31, 0.30, rect), control1: p(0.37, 0.29, rect), control2: p(0.34, 0.29, rect))
        path.addCurve(to: p(0.27, 0.36, rect), control1: p(0.28, 0.31, rect), control2: p(0.27, 0.33, rect))
        path.addCurve(to: p(0.24, 0.54, rect), control1: p(0.27, 0.42, rect), control2: p(0.25, 0.48, rect))
        path.addCurve(to: p(0.18, 0.70, rect), control1: p(0.23, 0.60, rect), control2: p(0.20, 0.65, rect))
        path.addCurve(to: p(0.14, 0.78, rect), control1: p(0.17, 0.73, rect), control2: p(0.15, 0.75, rect))
        path.addCurve(to: p(0.16, 0.84, rect), control1: p(0.12, 0.82, rect), control2: p(0.14, 0.84, rect))
        path.addCurve(to: p(0.20, 0.79, rect), control1: p(0.18, 0.86, rect), control2: p(0.20, 0.83, rect))
        path.addCurve(to: p(0.23, 0.73, rect), control1: p(0.20, 0.77, rect), control2: p(0.21, 0.75, rect))
        path.addCurve(to: p(0.29, 0.57, rect), control1: p(0.25, 0.68, rect), control2: p(0.28, 0.63, rect))
        path.addCurve(to: p(0.34, 0.42, rect), control1: p(0.30, 0.51, rect), control2: p(0.32, 0.46, rect))
        path.addCurve(to: p(0.37, 0.61, rect), control1: p(0.36, 0.50, rect), control2: p(0.36, 0.56, rect))
        path.addCurve(to: p(0.40, 0.67, rect), control1: p(0.38, 0.64, rect), control2: p(0.39, 0.66, rect))
        path.addCurve(to: p(0.36, 0.82, rect), control1: p(0.38, 0.72, rect), control2: p(0.36, 0.77, rect))
        path.addCurve(to: p(0.35, 0.93, rect), control1: p(0.36, 0.87, rect), control2: p(0.36, 0.90, rect))
        path.addCurve(to: p(0.31, 0.98, rect), control1: p(0.34, 0.95, rect), control2: p(0.31, 0.96, rect))
        path.addCurve(to: p(0.45, 0.98, rect), control1: p(0.30, 1.01, rect), control2: p(0.43, 1.00, rect))
        path.addCurve(to: p(0.48, 0.82, rect), control1: p(0.47, 0.93, rect), control2: p(0.47, 0.88, rect))
        path.addCurve(to: p(0.50, 0.67, rect), control1: p(0.48, 0.77, rect), control2: p(0.49, 0.72, rect))
        path.addCurve(to: p(0.52, 0.82, rect), control1: p(0.51, 0.72, rect), control2: p(0.52, 0.77, rect))
        path.addCurve(to: p(0.55, 0.98, rect), control1: p(0.53, 0.88, rect), control2: p(0.53, 0.93, rect))
        path.addCurve(to: p(0.69, 0.98, rect), control1: p(0.57, 1.00, rect), control2: p(0.70, 1.01, rect))
        path.addCurve(to: p(0.65, 0.93, rect), control1: p(0.69, 0.96, rect), control2: p(0.66, 0.95, rect))
        path.addCurve(to: p(0.64, 0.82, rect), control1: p(0.64, 0.90, rect), control2: p(0.64, 0.87, rect))
        path.addCurve(to: p(0.60, 0.67, rect), control1: p(0.64, 0.77, rect), control2: p(0.62, 0.72, rect))
        path.addCurve(to: p(0.63, 0.61, rect), control1: p(0.61, 0.66, rect), control2: p(0.62, 0.64, rect))
        path.addCurve(to: p(0.66, 0.42, rect), control1: p(0.64, 0.56, rect), control2: p(0.64, 0.50, rect))
        path.addCurve(to: p(0.71, 0.57, rect), control1: p(0.68, 0.46, rect), control2: p(0.70, 0.51, rect))
        path.addCurve(to: p(0.77, 0.73, rect), control1: p(0.72, 0.63, rect), control2: p(0.75, 0.68, rect))
        path.addCurve(to: p(0.80, 0.79, rect), control1: p(0.79, 0.75, rect), control2: p(0.80, 0.77, rect))
        path.addCurve(to: p(0.84, 0.84, rect), control1: p(0.80, 0.83, rect), control2: p(0.82, 0.86, rect))
        path.addCurve(to: p(0.86, 0.78, rect), control1: p(0.86, 0.84, rect), control2: p(0.88, 0.82, rect))
        path.addCurve(to: p(0.82, 0.70, rect), control1: p(0.85, 0.75, rect), control2: p(0.83, 0.73, rect))
        path.addCurve(to: p(0.76, 0.54, rect), control1: p(0.80, 0.65, rect), control2: p(0.77, 0.60, rect))
        path.addCurve(to: p(0.73, 0.36, rect), control1: p(0.75, 0.48, rect), control2: p(0.73, 0.42, rect))
        path.addCurve(to: p(0.69, 0.30, rect), control1: p(0.73, 0.33, rect), control2: p(0.72, 0.31, rect))
        path.addCurve(to: p(0.59, 0.28, rect), control1: p(0.66, 0.29, rect), control2: p(0.63, 0.29, rect))
        path.addLine(to: p(0.58, 0.24, rect))
        path.addCurve(to: p(0.62, 0.22, rect), control1: p(0.60, 0.24, rect), control2: p(0.61, 0.23, rect))
        path.addCurve(to: p(0.64, 0.15, rect), control1: p(0.63, 0.20, rect), control2: p(0.64, 0.18, rect))
        path.addCurve(to: p(0.61, 0.06, rect), control1: p(0.65, 0.12, rect), control2: p(0.64, 0.09, rect))
        path.addCurve(to: p(0.50, 0.03, rect), control1: p(0.59, 0.04, rect), control2: p(0.55, 0.03, rect))
        path.closeSubpath()

        return path
    }

    private func bodyPart(_ path: Path) -> some View {
        path
            .fill(fill)
    }

    private func headPath(in rect: CGRect) -> Path {
        Path(ellipseIn: CGRect(
            x: rect.minX + rect.width * 0.36,
            y: rect.minY + rect.height * 0.03,
            width: rect.width * 0.28,
            height: rect.height * 0.16
        ))
    }

    private func neckPath(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: p(0.43, 0.18, rect))
        path.addLine(to: p(0.57, 0.18, rect))
        path.addLine(to: p(0.61, 0.30, rect))
        path.addLine(to: p(0.39, 0.30, rect))
        path.closeSubpath()
        return path
    }

    private func torsoPath(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: p(0.28, 0.29, rect))
        path.addCurve(to: p(0.72, 0.29, rect), control1: p(0.39, 0.25, rect), control2: p(0.61, 0.25, rect))
        path.addCurve(to: p(0.70, 0.51, rect), control1: p(0.76, 0.36, rect), control2: p(0.73, 0.45, rect))
        path.addCurve(to: p(0.62, 0.63, rect), control1: p(0.68, 0.57, rect), control2: p(0.66, 0.61, rect))
        path.addCurve(to: p(0.50, 0.65, rect), control1: p(0.58, 0.65, rect), control2: p(0.54, 0.66, rect))
        path.addCurve(to: p(0.38, 0.63, rect), control1: p(0.46, 0.66, rect), control2: p(0.42, 0.65, rect))
        path.addCurve(to: p(0.30, 0.51, rect), control1: p(0.34, 0.61, rect), control2: p(0.32, 0.57, rect))
        path.addCurve(to: p(0.28, 0.29, rect), control1: p(0.27, 0.45, rect), control2: p(0.24, 0.36, rect))
        path.closeSubpath()
        return path
    }

    private func leftArmPath(in rect: CGRect) -> Path {
        armPath(in: rect, left: true)
    }

    private func rightArmPath(in rect: CGRect) -> Path {
        armPath(in: rect, left: false)
    }

    private func armPath(in rect: CGRect, left: Bool) -> Path {
        func x(_ frontX: CGFloat) -> CGFloat {
            left ? frontX : 1 - frontX
        }

        var path = Path()
        path.move(to: p(x(0.31), 0.31, rect))
        path.addCurve(to: p(x(0.20), 0.60, rect), control1: p(x(0.22), 0.40, rect), control2: p(x(0.23), 0.51, rect))
        path.addCurve(to: p(x(0.10), 0.74, rect), control1: p(x(0.19), 0.66, rect), control2: p(x(0.14), 0.70, rect))
        path.addCurve(to: p(x(0.07), 0.80, rect), control1: p(x(0.06), 0.77, rect), control2: p(x(0.05), 0.79, rect))
        path.addCurve(to: p(x(0.16), 0.80, rect), control1: p(x(0.09), 0.84, rect), control2: p(x(0.14), 0.82, rect))
        path.addCurve(to: p(x(0.21), 0.73, rect), control1: p(x(0.17), 0.86, rect), control2: p(x(0.22), 0.82, rect))
        path.addCurve(to: p(x(0.29), 0.53, rect), control1: p(x(0.22), 0.66, rect), control2: p(x(0.27), 0.60, rect))
        path.addCurve(to: p(x(0.36), 0.34, rect), control1: p(x(0.30), 0.45, rect), control2: p(x(0.33), 0.39, rect))
        path.addCurve(to: p(x(0.31), 0.31, rect), control1: p(x(0.35), 0.32, rect), control2: p(x(0.33), 0.31, rect))
        path.closeSubpath()
        return path
    }

    private func leftLegPath(in rect: CGRect) -> Path {
        legPath(in: rect, left: true)
    }

    private func rightLegPath(in rect: CGRect) -> Path {
        legPath(in: rect, left: false)
    }

    private func legPath(in rect: CGRect, left: Bool) -> Path {
        let hipOuter: CGFloat = left ? 0.38 : 0.62
        let kneeOuter: CGFloat = left ? 0.34 : 0.66
        let ankleOuter: CGFloat = left ? 0.35 : 0.65
        let footOuter: CGFloat = left ? 0.28 : 0.72
        let footInner: CGFloat = left ? 0.48 : 0.52
        let inner: CGFloat = left ? 0.49 : 0.51

        var path = Path()
        path.move(to: p(hipOuter, 0.61, rect))
        path.addCurve(to: p(kneeOuter, 0.79, rect), control1: p(left ? 0.35 : 0.65, 0.68, rect), control2: p(kneeOuter, 0.73, rect))
        path.addCurve(to: p(ankleOuter, 0.93, rect), control1: p(kneeOuter, 0.86, rect), control2: p(ankleOuter, 0.90, rect))
        path.addCurve(to: p(footOuter, 0.97, rect), control1: p(left ? 0.33 : 0.67, 0.95, rect), control2: p(left ? 0.29 : 0.71, 0.95, rect))
        path.addCurve(to: p(footInner, 0.98, rect), control1: p(left ? 0.31 : 0.69, 1.00, rect), control2: p(left ? 0.44 : 0.56, 1.00, rect))
        path.addCurve(to: p(inner, 0.66, rect), control1: p(left ? 0.47 : 0.53, 0.89, rect), control2: p(left ? 0.48 : 0.52, 0.75, rect))
        path.addCurve(to: p(hipOuter, 0.61, rect), control1: p(left ? 0.47 : 0.53, 0.63, rect), control2: p(left ? 0.43 : 0.57, 0.61, rect))
        path.closeSubpath()
        return path
    }

}


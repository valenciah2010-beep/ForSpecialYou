import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

enum MealPDFExporter {
    static func export(imageData: Data, estimate: MealNutritionEstimate, savedAt: Date) -> URL? {
        let fileName = "Meal-Nutrition-\(Int(savedAt.timeIntervalSince1970)).pdf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        do {
            try renderer.writePDF(to: url) { context in
                context.beginPage()

                var y: CGFloat = 36
                y += drawText(
                    localizedAppString("Meal Nutrition Estimate"),
                    in: CGRect(x: 36, y: y, width: 540, height: 40),
                    font: .boldSystemFont(ofSize: 24),
                    color: UIColor(red: 0.12, green: 0.17, blue: 0.16, alpha: 1)
                ) + 8

                y += drawText(
                    localizedDateString(savedAt, dateStyle: .full, timeStyle: .short),
                    in: CGRect(x: 36, y: y, width: 540, height: 28),
                    font: .systemFont(ofSize: 12, weight: .semibold),
                    color: .secondaryLabel
                ) + 16

                if let image = UIImage(data: imageData) {
                    let imageRect = aspectFitRect(for: image.size, in: CGRect(x: 36, y: y, width: 260, height: 210))
                    image.draw(in: imageRect)
                }

                let metrics = [
                    "\(localizedAppString("Calories")): \(estimate.calories) \(localizedAppString("kcal"))",
                    "\(localizedAppString("Protein")): \(estimate.protein) g",
                    "\(localizedAppString("Carbs")): \(estimate.carbs) g",
                    "\(localizedAppString("Fat")): \(estimate.fat) g",
                    "\(localizedAppString("Fiber")): \(estimate.fiber) g",
                    "\(localizedAppString("Sugar")): \(estimate.sugar) g",
                    "\(localizedAppString("Confidence")): \(localizedAppString(estimate.confidence))"
                ].joined(separator: "\n")

                _ = drawText(
                    metrics,
                    in: CGRect(x: 320, y: y, width: 256, height: 210),
                    font: .systemFont(ofSize: 14, weight: .semibold),
                    color: .label
                )
                y += 230

                y += drawSection(title: localizedAppString("Summary"), body: localizedSavedAIText(estimate.summary), y: y, pageWidth: pageRect.width) + 12
                y += drawSection(title: localizedAppString("Recommendations"), body: bulletList(estimate.recommendations.map(localizedSavedAIText)), y: y, pageWidth: pageRect.width) + 12
                _ = drawSection(title: localizedAppString("Notes"), body: bulletList(estimate.notes.map(localizedSavedAIText)), y: y, pageWidth: pageRect.width)
            }

            return url
        } catch {
            return nil
        }
    }

    private static func drawSection(title: String, body: String, y: CGFloat, pageWidth: CGFloat) -> CGFloat {
        var currentY = y
        currentY += drawText(
            title,
            in: CGRect(x: 36, y: currentY, width: pageWidth - 72, height: 24),
            font: .boldSystemFont(ofSize: 15),
            color: UIColor(red: 0.12, green: 0.17, blue: 0.16, alpha: 1)
        ) + 6

        currentY += drawText(
            body.isEmpty ? localizedAppString("No information available.") : body,
            in: CGRect(x: 36, y: currentY, width: pageWidth - 72, height: 140),
            font: .systemFont(ofSize: 12, weight: .medium),
            color: .label
        )

        return currentY - y
    }

    private static func drawText(_ text: String, in rect: CGRect, font: UIFont, color: UIColor) -> CGFloat {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = 4
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
        let attributedText = NSAttributedString(string: text, attributes: attributes)
        let neededRect = attributedText.boundingRect(
            with: CGSize(width: rect.width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        attributedText.draw(in: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: min(rect.height, ceil(neededRect.height))))
        return min(rect.height, ceil(neededRect.height))
    }

    private static func bulletList(_ items: [String]) -> String {
        guard !items.isEmpty else { return "" }
        return items.map { "- \($0)" }.joined(separator: "\n")
    }

    private static func aspectFitRect(for imageSize: CGSize, in boundingRect: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return boundingRect }
        let scale = min(boundingRect.width / imageSize.width, boundingRect.height / imageSize.height)
        let width = imageSize.width * scale
        let height = imageSize.height * scale
        return CGRect(
            x: boundingRect.midX - width / 2,
            y: boundingRect.midY - height / 2,
            width: width,
            height: height
        )
    }
}


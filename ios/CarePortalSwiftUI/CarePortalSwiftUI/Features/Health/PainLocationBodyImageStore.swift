import SwiftUI
import PhotosUI
import UIKit
import Charts
import UniformTypeIdentifiers
import UserNotifications

enum PainLocationBodyImageStore {
    private static let fallbackAspectRatio: CGFloat = 0.5

    static func image(for side: PainBodySide) -> UIImage? {
        guard let source = UIImage(named: "PainLocationBody") ?? UIImage(named: "PainLocationBody.jpg"),
              let cgImage = source.cgImage else {
            return nil
        }

        let halfWidth = cgImage.width / 2
        let cropRect = CGRect(
            x: side == .front ? 0 : halfWidth,
            y: 0,
            width: halfWidth,
            height: cgImage.height
        )

        guard let cropped = cgImage.cropping(to: cropRect) else {
            return source
        }

        return imageByRemovingWhiteBackground(from: cropped, scale: source.scale, orientation: source.imageOrientation)
    }

    static func aspectRatio(for side: PainBodySide) -> CGFloat {
        guard let image = image(for: side), image.size.height > 0 else {
            return fallbackAspectRatio
        }

        return image.size.width / image.size.height
    }

    static func containsBodyPixel(side: PainBodySide, x: CGFloat, y: CGFloat) -> Bool {
        guard let cgImage = image(for: side)?.cgImage else {
            return false
        }

        let width = cgImage.width
        let height = cgImage.height
        let clampedX = min(max(Int(round(x * CGFloat(width - 1))), 0), width - 1)
        let clampedY = min(max(Int(round(y * CGFloat(height - 1))), 0), height - 1)
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return false
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        let sampleRadius = 2
        for sampleY in max(0, clampedY - sampleRadius)...min(height - 1, clampedY + sampleRadius) {
            for sampleX in max(0, clampedX - sampleRadius)...min(width - 1, clampedX + sampleRadius) {
                let index = (sampleY * bytesPerRow) + (sampleX * bytesPerPixel)
                let red = pixels[index]
                let green = pixels[index + 1]
                let blue = pixels[index + 2]
                let alpha = pixels[index + 3]

                if alpha > 20 && (red < 248 || green < 248 || blue < 248) {
                    return true
                }
            }
        }

        return false
    }

    private static func imageByRemovingWhiteBackground(from cgImage: CGImage, scale: CGFloat, orientation: UIImage.Orientation) -> UIImage {
        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return UIImage(cgImage: cgImage, scale: scale, orientation: orientation)
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var visited = [Bool](repeating: false, count: width * height)
        var queue: [(x: Int, y: Int)] = []

        func pixelOffset(x: Int, y: Int) -> Int {
            (y * bytesPerRow) + (x * bytesPerPixel)
        }

        func pixelKey(x: Int, y: Int) -> Int {
            (y * width) + x
        }

        func isBackgroundPixel(x: Int, y: Int) -> Bool {
            let index = pixelOffset(x: x, y: y)
            let red = Int(pixels[index])
            let green = Int(pixels[index + 1])
            let blue = Int(pixels[index + 2])
            let brightness = max(red, green, blue)
            let darkness = min(red, green, blue)

            return brightness >= 228 && brightness - darkness <= 18
        }

        func enqueueIfBackground(x: Int, y: Int) {
            guard x >= 0, x < width, y >= 0, y < height else { return }
            let key = pixelKey(x: x, y: y)
            guard !visited[key], isBackgroundPixel(x: x, y: y) else { return }
            visited[key] = true
            queue.append((x, y))
        }

        for x in 0..<width {
            enqueueIfBackground(x: x, y: 0)
            enqueueIfBackground(x: x, y: height - 1)
        }

        for y in 0..<height {
            enqueueIfBackground(x: 0, y: y)
            enqueueIfBackground(x: width - 1, y: y)
        }

        var head = 0
        while head < queue.count {
            let point = queue[head]
            head += 1

            pixels[pixelOffset(x: point.x, y: point.y) + 3] = 0

            enqueueIfBackground(x: point.x + 1, y: point.y)
            enqueueIfBackground(x: point.x - 1, y: point.y)
            enqueueIfBackground(x: point.x, y: point.y + 1)
            enqueueIfBackground(x: point.x, y: point.y - 1)
        }

        guard let transparentContext = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ), let transparentImage = transparentContext.makeImage() else {
            return UIImage(cgImage: cgImage, scale: scale, orientation: orientation)
        }

        return UIImage(cgImage: transparentImage, scale: scale, orientation: orientation)
    }
}


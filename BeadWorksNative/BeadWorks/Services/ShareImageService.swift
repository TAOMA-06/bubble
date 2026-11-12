import SwiftUI
import UIKit

/// Composes a 1080×1920 share card (warm paper, work preview, metadata, watermark), matching
/// the native slice of Unity `ShareCaptureService`.
enum ShareImageService {
    static let canvasSize = CGSize(width: 1080, height: 1920)

    static func composeCard(
        boardImage: UIImage,
        title: String,
        beadCount: Int,
        width: Int,
        height: Int,
        productType: FinishedProductType,
        date: Date = Date()
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        return renderer.image { context in
            let cg = context.cgContext
            let rect = CGRect(origin: .zero, size: canvasSize)

            drawBackground(in: cg, rect: rect)
            drawHeader(title: title, productType: productType)
            drawBoard(boardImage, in: cg)
            drawMeta(beadCount: beadCount, width: width, height: height, date: date)
            drawWatermark()
        }
    }

    private static func drawBackground(in cg: CGContext, rect: CGRect) {
        let colors = [
            UIColor(red: 1, green: 0.973, blue: 0.910, alpha: 1).cgColor,
            UIColor(red: 0.965, green: 0.886, blue: 0.761, alpha: 1).cgColor,
            UIColor(red: 0.937, green: 0.824, blue: 0.659, alpha: 1).cgColor,
        ] as CFArray
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.55, 1]) {
            cg.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: rect.height), options: [])
        }
    }

    private static func drawHeader(title: String, productType: FinishedProductType) {
        let brand = NSAttributedString(
            string: "拼豆工坊",
            attributes: [
                .font: UIFont.systemFont(ofSize: 28, weight: .semibold),
                .foregroundColor: UIColor(red: 0.20, green: 0.14, blue: 0.12, alpha: 0.55),
            ]
        )
        brand.draw(at: CGPoint(x: 80, y: 96))

        let titleRect = CGRect(x: 80, y: 140, width: canvasSize.width - 160, height: 120)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left
        paragraph.lineBreakMode = .byTruncatingTail
        (title as NSString).draw(
            in: titleRect,
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 56, weight: .heavy),
                .foregroundColor: UIColor(red: 0.20, green: 0.14, blue: 0.12, alpha: 1),
                .paragraphStyle: paragraph,
            ]
        )

        let product = NSAttributedString(
            string: productType.displayName,
            attributes: [
                .font: UIFont.systemFont(ofSize: 28, weight: .medium),
                .foregroundColor: UIColor(red: 0.94, green: 0.35, blue: 0.16, alpha: 1),
            ]
        )
        product.draw(at: CGPoint(x: 80, y: 268))
    }

    private static func drawBoard(_ image: UIImage, in cg: CGContext) {
        let maxSide: CGFloat = 780
        let imageSize = image.size
        let scale = min(maxSide / max(imageSize.width, 1), maxSide / max(imageSize.height, 1))
        let drawSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let origin = CGPoint(
            x: (canvasSize.width - drawSize.width) / 2,
            y: 360
        )
        let card = CGRect(origin: origin, size: drawSize).insetBy(dx: -28, dy: -28)
        UIColor(red: 1, green: 0.992, blue: 0.973, alpha: 1).setFill()
        UIBezierPath(roundedRect: card, cornerRadius: 36).fill()
        UIColor(red: 0.24, green: 0.17, blue: 0.14, alpha: 0.16).setStroke()
        UIBezierPath(roundedRect: card, cornerRadius: 36).stroke()
        image.draw(in: CGRect(origin: origin, size: drawSize))
        _ = cg
    }

    private static func drawMeta(beadCount: Int, width: Int, height: Int, date: Date) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy.MM.dd"
        let line = "\(width)×\(height) · \(beadCount) 颗 · \(formatter.string(from: date))"
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        (line as NSString).draw(
            in: CGRect(x: 80, y: 1240, width: canvasSize.width - 160, height: 48),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 28, weight: .medium),
                .foregroundColor: UIColor(red: 0.20, green: 0.14, blue: 0.12, alpha: 0.62),
                .paragraphStyle: paragraph,
            ]
        )
    }

    private static func drawWatermark() {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        ("BeadWorks  ·  bubble" as NSString).draw(
            in: CGRect(x: 80, y: 1780, width: canvasSize.width - 160, height: 40),
            withAttributes: [
                .font: UIFont.systemFont(ofSize: 22, weight: .semibold),
                .foregroundColor: UIColor(red: 0.20, green: 0.14, blue: 0.12, alpha: 0.35),
                .paragraphStyle: paragraph,
            ]
        )
    }
}

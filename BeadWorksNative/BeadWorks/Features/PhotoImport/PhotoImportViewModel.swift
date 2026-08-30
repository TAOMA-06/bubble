import Observation
import PhotosUI
import SwiftUI
import UIKit

@MainActor
@Observable
final class PhotoImportViewModel {
    var selectedItem: PhotosPickerItem?
    var sourceImage: UIImage?
    var gridSize: Int = PhotoTemplateService.defaultSize
    var pattern: BeadPattern?
    var isLoading = false
    var errorMessage: String?

    var isUITestFixtureEnabled: Bool { UITestLaunch.usesFixtureImage }

    func loadImage(from item: PhotosPickerItem?) async {
        guard let item else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            guard let data = try await item.loadTransferable(type: Data.self), let image = UIImage(data: data) else {
                errorMessage = "无法读取所选照片"
                return
            }
            sourceImage = image
            await regenerate()
        } catch {
            errorMessage = "读取照片失败，请重试"
        }
    }

    func loadFixtureImage() async {
        sourceImage = Self.makeFixtureImage()
        await regenerate()
    }

    func regenerate() async {
        guard let sourceImage else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            pattern = try await PhotoTemplateService.makePatternAsync(from: sourceImage, gridSize: gridSize)
        } catch {
            errorMessage = "生成拼豆模板失败"
        }
    }

    func reset() {
        pattern = nil
        sourceImage = nil
        selectedItem = nil
        errorMessage = nil
    }

    static func makeFixtureImage() -> UIImage {
        let tile = 16
        let size = CGSize(width: tile * 4, height: tile * 4)
        let renderer = UIGraphicsImageRenderer(size: size)
        let colors: [UIColor] = [.systemRed, .systemBlue, .systemGreen, .systemYellow]
        return renderer.image { _ in
            for row in 0..<4 {
                for col in 0..<4 {
                    colors[(row + col) % colors.count].setFill()
                    UIRectFill(CGRect(x: col * tile, y: row * tile, width: tile, height: tile))
                }
            }
        }
    }
}

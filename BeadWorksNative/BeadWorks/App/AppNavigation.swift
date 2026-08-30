import Foundation

enum Route: Hashable {
    case editor(EditorContext)
    case photoImport
    case patternSelect
    case gallery
    case galleryDetail(GalleryWork)
}

import Foundation

/// In-progress editor snapshot so leaving the workbench does not lose unsaved beads.
struct WorkshopDraft: Codable, Equatable {
    var context: EditorContext
    var board: BeadBoard
    var selectedColorId: Int
    var updatedAt: Date
}

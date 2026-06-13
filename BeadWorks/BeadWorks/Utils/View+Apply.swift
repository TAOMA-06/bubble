import SwiftUI

extension View {
    @ViewBuilder
    func apply(@ViewBuilder transform: (Self) -> some View) -> some View {
        transform(self)
    }
}

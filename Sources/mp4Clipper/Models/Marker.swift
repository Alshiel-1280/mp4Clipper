import Foundation

struct Marker: Identifiable, Equatable {
    let id: UUID
    var timestamp: Double
    var memo: String
    var clipStartOffsetSec: Double
    var clipEndOffsetSec: Double
    var isSelected: Bool

    init(
        id: UUID = UUID(),
        timestamp: Double,
        memo: String = "",
        clipStartOffsetSec: Double,
        clipEndOffsetSec: Double,
        isSelected: Bool = true
    ) {
        self.id = id
        self.timestamp = timestamp
        self.memo = memo
        self.clipStartOffsetSec = clipStartOffsetSec
        self.clipEndOffsetSec = clipEndOffsetSec
        self.isSelected = isSelected
    }
}

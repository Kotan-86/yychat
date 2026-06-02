// 仕様: docs/spec/timeline-screen.md#タイムライン表示
import Foundation

struct TimelineMessage: Identifiable {
    enum Direction { case sent; case received }
    enum Status { case partial; case final_ }

    let id: UUID
    var direction: Direction
    var text: String
    var status: Status
}

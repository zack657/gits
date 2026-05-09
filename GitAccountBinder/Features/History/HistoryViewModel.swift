import Foundation
import Observation

@Observable
final class HistoryViewModel {
    private(set) var snapshots: [ConfigSnapshot] = []
    var errorMessage: String?

    private let snapshotService: SnapshotService?

    init(snapshotService: SnapshotService? = nil) {
        self.snapshotService = snapshotService
    }

    func setSnapshots(_ snapshots: [ConfigSnapshot]) {
        self.snapshots = snapshots
    }

    func restore(snapshot: ConfigSnapshot) {
        do {
            try snapshotService?.restore(snapshot: snapshot)
            errorMessage = "已恢复到 \(snapshot.createdAt.formatted()) 的版本。"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

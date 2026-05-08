import Foundation
import Observation

@Observable
final class HistoryViewModel {
    private(set) var snapshots: [ConfigSnapshot] = []

    func setSnapshots(_ snapshots: [ConfigSnapshot]) {
        self.snapshots = snapshots
    }
}

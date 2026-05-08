import Foundation
import Observation

@Observable
final class WorkspaceDefaultsViewModel {
    private(set) var rules: [WorkspaceRule] = []

    func setRules(_ rules: [WorkspaceRule]) {
        self.rules = rules
    }
}

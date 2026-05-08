import Foundation
import Observation

@Observable
final class DiagnosticsViewModel {
    private let diagnosticsService: DiagnosticsService
    private(set) var repositoryPath: String = ""
    private(set) var explanation: String = "暂无诊断结果"

    init(diagnosticsService: DiagnosticsService = DiagnosticsService()) {
        self.diagnosticsService = diagnosticsService
    }

    func update(repositoryPath: String, result: ResolutionResult) {
        self.repositoryPath = repositoryPath
        self.explanation = diagnosticsService.explanation(for: result)
    }
}

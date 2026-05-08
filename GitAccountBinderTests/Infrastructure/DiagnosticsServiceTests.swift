import Foundation
import Testing
@testable import GitAccountBinder

struct DiagnosticsServiceTests {
    @Test
    func diagnosticsExplainsRepositoryBindingInChinese() {
        let service = DiagnosticsService()
        let result = ResolutionResult(
            repositoryPath: "/tmp/repo-a",
            accountID: UUID(),
            reason: .repositoryBinding
        )

        let message = service.explanation(for: result)

        #expect(message == "该仓库使用显式绑定的账号。")
    }
}

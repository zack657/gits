import Foundation

struct DiagnosticsService {
    func explanation(for result: ResolutionResult) -> String {
        switch result.reason {
        case .repositoryBinding:
            return "该仓库使用显式绑定的账号。"
        case .workspaceRule:
            return "该仓库使用目录默认账号。"
        case .globalDefault:
            return "该仓库使用全局默认账号。"
        case .unresolved:
            return "该仓库当前还没有可用账号，请先绑定或设置默认值。"
        }
    }
}

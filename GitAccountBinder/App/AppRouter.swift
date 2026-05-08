import Foundation

struct AppRouter {
    enum SidebarDestination: Hashable {
        case accounts
        case repositories
        case workspaceDefaults
        case history
        case diagnostics
    }

    let defaultSidebarSelection: SidebarDestination = .accounts
}

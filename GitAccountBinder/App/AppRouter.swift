import Foundation

struct AppRouter {
    enum SidebarDestination: Hashable {
        case workbench
        case history
        case diagnostics
    }

    let defaultSidebarSelection: SidebarDestination = .workbench
}

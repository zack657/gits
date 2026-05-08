import Foundation

struct AppRouter {
    enum SidebarDestination: Hashable {
        case accounts
        case repositories
    }

    let defaultSidebarSelection: SidebarDestination = .accounts
}

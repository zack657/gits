import Foundation

@MainActor
@Observable
final class AppRouter {
    enum SidebarDestination: Hashable {
        case accounts
        case repositories
    }

    let defaultSidebarSelection: SidebarDestination = .accounts
}

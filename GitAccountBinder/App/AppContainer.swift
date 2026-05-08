import Foundation

@MainActor
struct AppContainer {
    let router: AppRouter

    static func bootstrap() -> AppContainer {
        AppContainer(router: AppRouter())
    }
}

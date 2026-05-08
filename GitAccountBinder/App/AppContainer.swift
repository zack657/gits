import Foundation

@MainActor
struct AppContainer {
    let router: AppRouter
    let homeViewModel: HomeViewModel

    static func bootstrap() -> AppContainer {
        AppContainer(router: AppRouter(), homeViewModel: HomeViewModel())
    }
}

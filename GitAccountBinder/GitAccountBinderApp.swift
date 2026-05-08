import SwiftUI

@main
struct GitAccountBinderApp: App {
    @State private var container = AppContainer.bootstrap()

    var body: some Scene {
        WindowGroup {
            HomeView(container: container)
                .environment(\.locale, Locale(identifier: "zh-Hans"))
        }
    }
}

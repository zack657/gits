import Testing
@testable import GitAccountBinder

@MainActor
struct AppContainerTests {
    @Test
    func bootstrapCreatesUsableViewModels() {
        let container = AppContainer.bootstrap()

        #expect(container.router.defaultSidebarSelection == .workbench)
        #expect(container.diagnosticsViewModel.explanation.isEmpty == false)
    }
}

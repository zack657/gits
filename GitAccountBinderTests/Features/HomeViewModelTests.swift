import Testing
@testable import GitAccountBinder

struct HomeViewModelTests {
    @Test
    func homeTitleUsesChineseDefaultCopy() {
        #expect(AppStrings.homeTitle == "Git 账号绑定器")
    }
}

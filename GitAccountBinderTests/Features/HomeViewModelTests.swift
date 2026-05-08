import Testing
@testable import GitAccountBinder

struct AppStringsTests {
    @Test
    func homeTitleUsesChineseDefaultCopy() {
        #expect(AppStrings.homeTitle == "Git 账号绑定器")
    }
}

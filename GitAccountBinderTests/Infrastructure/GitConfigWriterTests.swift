import Foundation
import Testing
@testable import GitAccountBinder

struct GitConfigWriterTests {
    @Test
    func previewIncludesGlobalGeneratedConfigAndRepositoryOverrides() throws {
        let preview = try ApplyPreviewService().buildPreview(
            repositoryPaths: ["/Users/ctw/work/app-api"],
            workspaceRuleRoots: ["/Users/ctw/work"],
            hasGlobalDefault: true
        )

        #expect(preview.filePaths.contains("~/.gitconfig"))
        #expect(preview.filePaths.contains("/Users/ctw/work/app-api/.git/config"))
    }
}

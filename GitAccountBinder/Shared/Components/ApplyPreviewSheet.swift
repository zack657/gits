import SwiftUI

struct ApplyPreviewSheet: View {
    let preview: ApplyPreview

    var body: some View {
        NavigationStack {
            List(preview.filePaths, id: \.self) { path in
                Text(path)
                    .font(.body.monospaced())
            }
            .navigationTitle("应用预览")
        }
    }
}

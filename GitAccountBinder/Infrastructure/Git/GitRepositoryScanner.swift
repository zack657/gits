import Foundation

struct GitRepositoryScanner {
    func scan(rootPaths: [String]) throws -> [RepositoryRecord] {
        let fileManager = FileManager.default
        var results: [RepositoryRecord] = []

        for rootPath in rootPaths {
            guard let enumerator = fileManager.enumerator(atPath: rootPath) else {
                continue
            }

            while let entry = enumerator.nextObject() as? String {
                guard entry == ".git" || entry.hasSuffix("/.git") else {
                    continue
                }

                let repositoryPath = URL(fileURLWithPath: rootPath)
                    .appendingPathComponent(entry)
                    .deletingLastPathComponent()
                    .path()

                results.append(
                    RepositoryRecord(
                        id: UUID(),
                        repositoryPath: repositoryPath,
                        repositoryName: URL(fileURLWithPath: repositoryPath).lastPathComponent,
                        lastScannedAt: .now
                    )
                )
                enumerator.skipDescendants()
            }
        }

        return results.sorted { $0.repositoryPath < $1.repositoryPath }
    }
}

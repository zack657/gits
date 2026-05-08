import Foundation

struct AppPathService {
    let root: String

    var sshDirectory: String {
        "\(root)/Keys"
    }

    var generatedConfigDirectory: String {
        "\(root)/Generated"
    }
}

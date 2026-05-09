import Foundation

protocol ShellCommandRunning {
    @discardableResult
    func run(_ launchPath: String, arguments: [String]) throws -> String
}

struct ShellCommandError: LocalizedError {
    let launchPath: String
    let arguments: [String]
    let output: String
    let terminationStatus: Int32

    var errorDescription: String? {
        "\(launchPath) failed with status \(terminationStatus): \(output)"
    }
}

struct ShellCommandRunner: ShellCommandRunning {
    func run(_ launchPath: String, arguments: [String]) throws -> String {
        let process = Process()
        let outputPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        try process.run()
        process.waitUntilExit()

        let output = String(
            data: outputPipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        ) ?? ""

        guard process.terminationStatus == 0 else {
            throw ShellCommandError(
                launchPath: launchPath,
                arguments: arguments,
                output: output,
                terminationStatus: process.terminationStatus
            )
        }

        return output
    }
}

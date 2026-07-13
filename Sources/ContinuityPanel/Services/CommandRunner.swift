import Foundation

struct CommandResult: Sendable {
    let status: Int32
    let output: String

    var succeeded: Bool { status == 0 }
}

enum CommandRunner {
    static func run(
        executable: URL,
        arguments: [String] = [],
        currentDirectory: URL? = nil,
        standardInput: Data? = nil,
        environment: [String: String] = [:]
    ) async throws -> CommandResult {
        try await Task.detached(priority: .userInitiated) {
            let process = Process()
            let outputPipe = Pipe()
            process.executableURL = executable
            process.arguments = arguments
            process.currentDirectoryURL = currentDirectory
            process.environment = ProcessInfo.processInfo.environment.merging(environment) { _, override in override }
            process.standardOutput = outputPipe
            process.standardError = outputPipe

            if let standardInput {
                let inputPipe = Pipe()
                process.standardInput = inputPipe
                try process.run()
                inputPipe.fileHandleForWriting.write(standardInput)
                try inputPipe.fileHandleForWriting.close()
            } else {
                try process.run()
            }

            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            return CommandResult(
                status: process.terminationStatus,
                output: String(decoding: data, as: UTF8.self)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }.value
    }
}

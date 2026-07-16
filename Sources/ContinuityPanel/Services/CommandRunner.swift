import Foundation

struct CommandResult: Sendable {
    let status: Int32
    let output: String

    var succeeded: Bool { status == 0 }
}

enum CommandRunner {
    static func runStreaming(
        executable: URL,
        arguments: [String] = [],
        currentDirectory: URL? = nil,
        environment: [String: String] = [:],
        onOutput: @escaping @Sendable (String) async -> Void
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

            try process.run()
            var collected = Data()
            while true {
                let chunk = outputPipe.fileHandleForReading.availableData
                guard !chunk.isEmpty else { break }
                collected.append(chunk)
                await onOutput(String(decoding: chunk, as: UTF8.self))
            }
            process.waitUntilExit()
            return CommandResult(
                status: process.terminationStatus,
                output: String(decoding: collected, as: UTF8.self)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }.value
    }

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

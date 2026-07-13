import Foundation

struct HermesConfigurationPayload: Codable, Sendable {
    let provider: String
    let model: String
    let keyEnvironment: String
    let apiKey: String
}

enum HermesConfigurationService {
    static func configure(provider: HermesProvider, model: String, apiKey: String) async throws -> CommandResult {
        let payload = HermesConfigurationPayload(
            provider: provider.rawValue,
            model: model,
            keyEnvironment: provider.keyEnvironment,
            apiKey: apiKey
        )
        let input = try JSONEncoder().encode(payload)
        let python = AppPaths.root.appendingPathComponent("home/.hermes/hermes-agent/venv/bin/python")
        let helper = AppPaths.root.appendingPathComponent("helpers/configure_hermes.py")
        return try await CommandRunner.run(
            executable: python,
            arguments: [helper.path],
            currentDirectory: AppPaths.root.appendingPathComponent("home/.hermes/hermes-agent"),
            standardInput: input
        )
    }
}

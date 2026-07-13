import Foundation

struct HermesConfigurationPayload: Codable, Sendable {
    let provider: String
    let model: String
    let environment: [String: String]
}

enum HermesConfigurationService {
    static func loadProviders() async throws -> [HermesProviderDescriptor] {
        let python = AppPaths.root.appendingPathComponent("home/.hermes/hermes-agent/venv/bin/python")
        let helper = AppPaths.root.appendingPathComponent("helpers/list_hermes_providers.py")
        let result = try await CommandRunner.run(
            executable: python,
            arguments: [helper.path],
            currentDirectory: AppPaths.root.appendingPathComponent("home/.hermes/hermes-agent")
        )
        guard result.succeeded else { throw StoreError.commandFailed(result.output) }
        return try JSONDecoder().decode([HermesProviderDescriptor].self, from: Data(result.output.utf8))
    }

    static func configure(
        provider: HermesProviderDescriptor,
        model: String,
        environment: [String: String]
    ) async throws -> CommandResult {
        let payload = HermesConfigurationPayload(
            provider: provider.slug,
            model: model,
            environment: environment
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

    static func authenticate(provider: HermesProviderDescriptor) async throws -> CommandResult {
        let hermes = AppPaths.root.appendingPathComponent("bin/hermes")
        return try await CommandRunner.run(
            executable: hermes,
            arguments: ["auth", "add", provider.slug, "--type", "oauth"],
            currentDirectory: AppPaths.root,
            standardInput: Data("\n".utf8)
        )
    }
}

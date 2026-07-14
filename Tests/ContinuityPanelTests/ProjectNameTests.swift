import Testing
@testable import ContinuityPanel

@Test func projectNameValidation() {
    #expect(ProjectName.isValid("my-app"))
    #expect(ProjectName.isValid("App_2026"))
    #expect(!ProjectName.isValid("../escape"))
    #expect(!ProjectName.isValid("has spaces"))
    #expect(!ProjectName.isValid(".hidden"))
}

@Test func projectNameSuggestionNormalizesImportedFolder() {
    #expect(ProjectName.suggested(from: "A minha aplicação") == "A_minha_aplicacao")
    #expect(ProjectName.suggested(from: "  snake game  ") == "snake_game")
    #expect(ProjectName.suggested(from: "../../escape") == "escape")
}

@Test func hermesProfileIdentifiersAreStableAndSafe() {
    #expect(HermesProfileID.suggested(from: "GLM 5.2 — NVIDIA NIM") == "glm-5-2-nvidia-nim")
    #expect(HermesProfileID.suggested(from: "Qwén Coder") == "qwen-coder")
    #expect(HermesProfileID.isValid("mimo-nim"))
    #expect(!HermesProfileID.isValid("../escape"))
    #expect(!HermesProfileID.isValid(HermesProfileID.defaultProfile))
}

@Test func builtInCatalogHasBroadCoverage() {
    #expect(AgentKind.allCases.count >= 10)
    #expect(CloudProvider.allCases.count >= 10)
}

@Test func missionControlIsThePrimarySection() {
    #expect(AppSection.allCases.first == .missionControl)
}

@Test func hermesProviderDescriptorClassifiesAccountLogin() {
    let provider = HermesProviderDescriptor(
        slug: "openai-codex",
        label: "OpenAI Codex",
        description: "Codex OAuth",
        authType: "oauth_external",
        tab: "accounts",
        signupURL: "",
        fields: [],
        defaultBaseURL: "https://example.invalid/v1",
        models: ["example-model"]
    )
    #expect(provider.usesAccountLogin)
    #expect(provider.authenticationLabel.contains("OAuth"))
    #expect(provider.hasModelCatalog)
}

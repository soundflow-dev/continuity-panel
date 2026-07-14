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

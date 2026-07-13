import Testing
@testable import ContinuityPanel

@Test func projectNameValidation() {
    #expect(ProjectName.isValid("my-app"))
    #expect(ProjectName.isValid("App_2026"))
    #expect(!ProjectName.isValid("../escape"))
    #expect(!ProjectName.isValid("has spaces"))
    #expect(!ProjectName.isValid(".hidden"))
}

@Test func builtInCatalogHasBroadCoverage() {
    #expect(AgentKind.allCases.count >= 10)
    #expect(CloudProvider.allCases.count >= 10)
}

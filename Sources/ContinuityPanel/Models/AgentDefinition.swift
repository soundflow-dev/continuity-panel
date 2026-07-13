import Foundation

enum AgentKind: String, CaseIterable, Identifiable, Sendable {
    case codex
    case hermes
    case claude
    case gemini
    case copilot
    case opencode
    case goose
    case aider
    case qwen
    case kimi

    var id: Self { self }

    var title: String {
        switch self {
        case .codex: "Codex"
        case .hermes: "Hermes Agent"
        case .claude: "Claude Code"
        case .gemini: "Gemini CLI"
        case .copilot: "GitHub Copilot CLI"
        case .opencode: "OpenCode"
        case .goose: "goose"
        case .aider: "Aider"
        case .qwen: "Qwen Code"
        case .kimi: "Kimi Code"
        }
    }

    var summary: String {
        switch self {
        case .codex: "OpenAI coding agent with browser-based account login."
        case .hermes: "Provider-independent agent that can switch between cloud models."
        case .claude: "Anthropic's coding agent, supporting Claude accounts and API access."
        case .gemini: "Google's open-source terminal agent for Gemini models."
        case .copilot: "GitHub's terminal coding agent with Copilot and BYOK support."
        case .opencode: "Open-source coding agent with a broad provider ecosystem."
        case .goose: "Linux Foundation agent with many providers and MCP extensions."
        case .aider: "Git-native pair-programming agent supporting many cloud models."
        case .qwen: "Open-source agent optimized for Qwen and compatible providers."
        case .kimi: "Moonshot AI's fast coding agent with OAuth and API-key options."
        }
    }

    var systemImage: String {
        switch self {
        case .codex: "chevron.left.forwardslash.chevron.right"
        case .hermes: "network"
        case .claude: "sparkles"
        case .gemini: "diamond"
        case .copilot: "infinity"
        case .opencode: "terminal"
        case .goose: "bird"
        case .aider: "arrow.triangle.branch"
        case .qwen: "q.circle"
        case .kimi: "moon.stars"
        }
    }

    var binaryRelativePath: String {
        switch self {
        case .hermes: "home/.hermes/hermes-agent/venv/bin/hermes"
        case .goose: "tools/goose/bin/goose"
        case .aider: "tools/aider/bin/aider"
        default: "tools/\(rawValue)/bin/\(executableName)"
        }
    }

    var executableName: String {
        switch self {
        case .claude: "claude"
        case .gemini: "gemini"
        case .copilot: "copilot"
        case .opencode: "opencode"
        case .qwen: "qwen"
        case .kimi: "kimi"
        default: rawValue
        }
    }
}

struct HermesProviderField: Codable, Hashable, Identifiable, Sendable {
    let name: String
    let label: String
    let secret: Bool
    let required: Bool

    var id: String { name }
}

struct HermesProviderDescriptor: Codable, Hashable, Identifiable, Sendable {
    let slug: String
    let label: String
    let description: String
    let authType: String
    let tab: String
    let signupURL: String
    let fields: [HermesProviderField]

    var id: String { slug }

    var usesAccountLogin: Bool { tab == "accounts" }
    var supportsBrowserLogin: Bool {
        ["oauth_device_code", "oauth_external", "oauth_minimax"].contains(authType)
    }

    var authenticationLabel: String {
        switch authType {
        case "oauth_device_code": "Browser sign-in (device code)"
        case "oauth_external", "oauth_minimax": "Browser sign-in (OAuth)"
        case "external_process", "copilot": "External account or process"
        case "aws_sdk": "AWS credential chain"
        case "vertex": "Google Cloud credentials"
        case "virtual": "No credentials required"
        default: "API key"
        }
    }
}

enum CloudProvider: String, CaseIterable, Identifiable, Sendable {
    case openAI
    case anthropic
    case openRouter
    case google
    case zai
    case mistral
    case groq
    case xai
    case deepSeek
    case moonshot

    var id: Self { self }

    var title: String {
        switch self {
        case .openAI: "OpenAI API"
        case .anthropic: "Anthropic"
        case .openRouter: "OpenRouter"
        case .google: "Google Gemini"
        case .zai: "Z.AI / GLM"
        case .mistral: "Mistral AI"
        case .groq: "Groq"
        case .xai: "xAI"
        case .deepSeek: "DeepSeek"
        case .moonshot: "Moonshot / Kimi"
        }
    }

    var keyEnvironment: String {
        switch self {
        case .openAI: "OPENAI_API_KEY"
        case .anthropic: "ANTHROPIC_API_KEY"
        case .openRouter: "OPENROUTER_API_KEY"
        case .google: "GEMINI_API_KEY"
        case .zai: "ZAI_API_KEY"
        case .mistral: "MISTRAL_API_KEY"
        case .groq: "GROQ_API_KEY"
        case .xai: "XAI_API_KEY"
        case .deepSeek: "DEEPSEEK_API_KEY"
        case .moonshot: "MOONSHOT_API_KEY"
        }
    }

    var systemImage: String {
        switch self {
        case .openAI: "brain"
        case .anthropic: "sparkles"
        case .openRouter: "arrow.triangle.swap"
        case .google: "diamond"
        case .zai: "z.circle"
        case .mistral: "wind"
        case .groq: "bolt"
        case .xai: "xmark.circle"
        case .deepSeek: "scope"
        case .moonshot: "moon"
        }
    }
}

import AppKit
import Security
import ServiceManagement

struct LocalProviderDetection {
    let provider: Provider
    let path: String
}

enum ProviderDiscovery {
    private static let home = FileManager.default.homeDirectoryForCurrentUser.path

    private static let candidates: [Provider: [String]] = [
        .claude: [
            "/Applications/Claude.app", home + "/Applications/Claude.app",
            "/opt/homebrew/bin/claude", "/usr/local/bin/claude", home + "/.local/bin/claude"
        ],
        .gemini: [
            "/Applications/Gemini.app", home + "/Applications/Gemini.app",
            "/opt/homebrew/bin/gemini", "/usr/local/bin/gemini", home + "/.local/bin/gemini"
        ],
        .kimi: [
            "/Applications/Kimi.app", home + "/Applications/Kimi.app",
            "/opt/homebrew/bin/kimi", "/usr/local/bin/kimi", home + "/.local/bin/kimi"
        ],
        .qwen: [
            "/Applications/通义.app", "/Applications/Qwen.app", home + "/Applications/Qwen.app",
            "/opt/homebrew/bin/qwen", "/opt/homebrew/bin/qwen-code",
            "/usr/local/bin/qwen", "/usr/local/bin/qwen-code"
        ],
        .doubao: [
            "/Applications/豆包.app", "/Applications/Doubao.app",
            home + "/Applications/豆包.app", home + "/Applications/Doubao.app"
        ],
        .zhipu: [
            "/Applications/智谱清言.app", home + "/Applications/智谱清言.app",
            "/opt/homebrew/bin/zai", "/usr/local/bin/zai", home + "/.local/bin/zai"
        ],
        .minimax: [
            "/Applications/MiniMax.app", home + "/Applications/MiniMax.app",
            "/opt/homebrew/bin/mmx", "/usr/local/bin/mmx", home + "/.local/bin/mmx"
        ],
        .wenxin: [
            "/Applications/文心一言.app", "/Applications/文小言.app",
            home + "/Applications/文心一言.app", home + "/Applications/文小言.app"
        ],
        .hunyuan: [
            "/Applications/腾讯元宝.app", home + "/Applications/腾讯元宝.app",
            "/Applications/Yuanbao.app", home + "/Applications/Yuanbao.app"
        ]
    ]

    static func scan() -> [LocalProviderDetection] {
        let fm = FileManager.default
        return candidates.compactMap { provider, paths in
            guard let path = paths.first(where: { fm.fileExists(atPath: $0) }) else { return nil }
            return LocalProviderDetection(provider: provider, path: path)
        }.sorted { $0.provider.displayName < $1.provider.displayName }
    }
}

enum DeepSeekKeychain {
    private static let service = "com.bsstxbel.api-quota-dashboard.deepseek"

    static func save(account: String, apiKey: String) -> Bool {
        let account = account.trimmingCharacters(in: .whitespacesAndNewlines)
        let apiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !account.isEmpty, !apiKey.isEmpty, let data = apiKey.data(using: .utf8) else { return false }

        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let updateStatus = SecItemUpdate(base as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if updateStatus == errSecSuccess { return true }

        var add = base
        add[kSecValueData as String] = data
        return SecItemAdd(add as CFDictionary, nil) == errSecSuccess
    }

    static func apiKey(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func accounts() -> [String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let entries = item as? [[String: Any]] else { return [] }
        return entries.compactMap { $0[kSecAttrAccount as String] as? String }.sorted()
    }

    static func delete(account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

enum ProviderCredentialKeychain {
    private static let servicePrefix = "com.bsstxbel.api-quota-dashboard.provider."

    static func save(provider: Provider, apiKey: String) -> Bool {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty, let data = key.data(using: .utf8) else { return false }
        let service = servicePrefix + provider.rawValue
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "default"
        ]
        if SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary) == errSecSuccess {
            return true
        }
        var add = query
        add[kSecValueData as String] = data
        return SecItemAdd(add as CFDictionary, nil) == errSecSuccess
    }

    static func apiKey(provider: Provider) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: servicePrefix + provider.rawValue,
            kSecAttrAccount as String: "default",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(provider: Provider) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: servicePrefix + provider.rawValue,
            kSecAttrAccount as String: "default"
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

enum LaunchAtLoginManager {
    static let label = "com.bsstxbel.api-quota-dashboard"

    static var plistURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents", isDirectory: true)
            .appendingPathComponent(label + ".plist")
    }

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
            || FileManager.default.fileExists(atPath: plistURL.path)
    }

    static func setEnabled(_ enabled: Bool) throws {
        let service = SMAppService.mainApp
        if !enabled {
            if service.status == .enabled { try service.unregister() }
            if FileManager.default.fileExists(atPath: plistURL.path) {
                try FileManager.default.removeItem(at: plistURL)
            }
            return
        }

        let applicationPath = Bundle.main.bundleURL.path
        guard applicationPath.hasSuffix(".app") else {
            throw NSError(domain: label, code: 1, userInfo: [NSLocalizedDescriptionKey: "未找到应用程序包"])
        }
        if service.status != .enabled { try service.register() }

        // 2.0 uses Apple's login-item API. Remove the legacy LaunchAgent only
        // after registration succeeds so existing users are migrated safely.
        if FileManager.default.fileExists(atPath: plistURL.path) {
            try FileManager.default.removeItem(at: plistURL)
        }
    }
}

struct VolcProfileList: Codable {
    let defaultProfile: String?
    let profiles: [VolcProfile]
}

struct VolcProfile: Codable {
    let name: String
    let displayName: String?
    let type: String?
    let region: String?
    let project: String?
    let isDefault: Bool?
}

struct VolcPlanResponse: Codable {
    let items: [VolcPlanItem]
}

struct VolcPlanItem: Codable {
    let product: String
    let edition: String?
    let tier: String?
    let subscribed: Bool
    let periods: [VolcPlanPeriod]
}

struct VolcPlanPeriod: Codable {
    let label: String
    let used: Double?
    let total: Double?
    let percent: Double?
    let resetAt: String?

    var remainingPercent: Double? {
        guard let percent else { return nil }
        return max(0, min(100, 100 - percent))
    }
}

struct VolcPlanSummary {
    let items: [VolcPlanItem]

    var primaryItem: VolcPlanItem? {
        items.first(where: { $0.subscribed && !$0.periods.isEmpty })
    }

    var primaryPeriod: VolcPlanPeriod? {
        guard let item = primaryItem else { return nil }
        let order = ["weekly", "session", "monthly", "5h"]
        for label in order {
            if let period = item.periods.first(where: { $0.label == label }) { return period }
        }
        return item.periods.first
    }
}

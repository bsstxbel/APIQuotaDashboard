import AppKit
import CFNetwork

// MARK: - Provider

enum Provider: String, Codable, CaseIterable {
    case deepseek = "deepseek"
    case volcengine = "volcengine"
    case codex = "codex"
    case claude = "claude"
    case gemini = "gemini"
    case kimi = "kimi"
    case qwen = "qwen"
    case doubao = "doubao"
    case zhipu = "zhipu"
    case minimax = "minimax"
    case openai = "openai"
    case openrouter = "openrouter"
    case siliconflow = "siliconflow"
    case wenxin = "wenxin"
    case hunyuan = "hunyuan"

    var displayName: String {
        switch self {
        case .deepseek: return "DeepSeek"
        case .volcengine: return "火山引擎"
        case .codex: return "Codex"
        case .claude: return "Claude"
        case .gemini: return "Gemini"
        case .kimi: return "Kimi"
        case .qwen: return "通义千问"
        case .doubao: return "豆包"
        case .zhipu: return "智谱 GLM"
        case .minimax: return "MiniMax"
        case .openai: return "OpenAI API"
        case .openrouter: return "OpenRouter"
        case .siliconflow: return "硅基流动"
        case .wenxin: return "文心千帆"
        case .hunyuan: return "腾讯混元"
        }
    }

    var shortName: String {
        switch self {
        case .deepseek: return "DS"
        case .volcengine: return "火山"
        case .codex: return "Codex"
        case .claude: return "Claude"
        case .gemini: return "Gemini"
        case .kimi: return "Kimi"
        case .qwen: return "千问"
        case .doubao: return "豆包"
        case .zhipu: return "GLM"
        case .minimax: return "MiniMax"
        case .openai: return "OpenAI"
        case .openrouter: return "OR"
        case .siliconflow: return "硅基"
        case .wenxin: return "文心"
        case .hunyuan: return "混元"
        }
    }

    var dashboardURL: URL? {
        let address: String
        switch self {
        case .deepseek: address = "https://platform.deepseek.com/usage"
        case .volcengine, .doubao: address = "https://console.volcengine.com/ark"
        case .codex: address = "https://chatgpt.com/codex/settings"
        case .claude: address = "https://console.anthropic.com/settings/usage"
        case .gemini: address = "https://aistudio.google.com/usage"
        case .kimi: address = "https://platform.moonshot.cn/console"
        case .qwen: address = "https://bailian.console.aliyun.com/"
        case .zhipu: address = "https://open.bigmodel.cn/finance-center/resource-package/package-mgmt?tab=my"
        case .minimax: address = "https://platform.minimaxi.com/"
        case .openai: address = "https://platform.openai.com/usage"
        case .openrouter: address = "https://openrouter.ai/activity"
        case .siliconflow: address = "https://cloud.siliconflow.cn/account/expense"
        case .wenxin: address = "https://console.bce.baidu.com/qianfan/overview"
        case .hunyuan: address = "https://console.cloud.tencent.com/hunyuan"
        }
        return URL(string: address)
    }

    var supportsQuotaQuery: Bool {
        switch self {
        case .deepseek, .volcengine, .codex, .claude, .gemini, .kimi, .qwen, .minimax,
             .openai, .openrouter, .siliconflow, .doubao, .zhipu:
            return true
        case .wenxin, .hunyuan:
            return false
        }
    }

    static var queryableCases: [Provider] {
        allCases.filter(\.supportsQuotaQuery)
    }

    var requiresAccountSetupForDisplay: Bool {
        switch self {
        case .claude, .gemini, .kimi, .qwen, .minimax, .openai, .openrouter, .siliconflow:
            return true
        default: return false
        }
    }

    var queryAvailabilityDescription: String {
        switch self {
        case .claude:
            return "个人订阅暂无官方余额接口；组织管理员可接入 Usage API"
        case .gemini:
            return "官方用量目前需通过 AI Studio / Cloud Billing 查看"
        case .kimi:
            return "开放平台支持 API Key 查询余额，个人会员与开放平台分开"
        case .qwen:
            return "开放平台支持 API Key 查询模型限额"
        case .minimax:
            return "Token Plan 可通过官方 mmx quota 查询"
        case .openai:
            return "组织管理员可通过官方 Costs API 查询最近 30 天成本"
        case .openrouter:
            return "使用 Management Key 查询已购额度、累计用量与剩余额度"
        case .siliconflow:
            return "使用 API Key 查询账户总余额、充值余额与赠送余额"
        case .doubao:
            return "使用本机已登录豆包会话后台查询当前时段和近 7 天额度；不读取聊天记录，也不会保存登录凭证"
        case .zhipu:
            return "使用本机 Chrome 中已登录的智谱会话查询资源包剩余量、适用范围、到期时间和账户余额；不保存登录凭证"
        case .wenxin, .hunyuan:
            return "当前仅检测本机软件，尚无已验证的通用余额接口"
        case .deepseek, .volcengine, .codex:
            return "已支持额度查询"
        }
    }

}

enum MenuBarDisplayMode: String, Codable, CaseIterable {
    case valueOnly = "value_only"
    case providerAndValue = "provider_and_value"

    var displayName: String {
        switch self {
        case .valueOnly: return "仅显示额度"
        case .providerAndValue: return "提供方 + 额度"
        }
    }
}

enum MenuBarQuotaDisplayMode: String, Codable, CaseIterable {
    case fiveHourOnly = "five_hour_only"
    case totalOnly = "total_only"
    case all = "all"

    var displayName: String {
        switch self {
        case .fiveHourOnly: return "只显示 5 小时"
        case .totalOnly: return "只显示总额"
        case .all: return "全部显示"
        }
    }
}

struct MenuBarDisplayLine {
    var text: String
    let percentage: Double?
    let horizontalOffset: CGFloat

    init(text: String, percentage: Double?, horizontalOffset: CGFloat = 0) {
        self.text = text
        self.percentage = percentage
        self.horizontalOffset = horizontalOffset
    }
}

enum IconAppearance: String, Codable, CaseIterable {
    case white
    case black
    case transparent
    case system

    var displayName: String {
        switch self {
        case .white: return "白色"
        case .black: return "黑色"
        case .transparent: return "透明"
        case .system: return "跟随系统"
        }
    }
}

// MARK: - DeepSeek Models

struct DSBalanceInfo: Codable {
    let currency: String
    let totalBalance: String
    let grantedBalance: String
    let toppedUpBalance: String
}

struct DSBalanceResponse: Codable {
    let isAvailable: Bool
    let balanceInfos: [DSBalanceInfo]
}

// MARK: - Volcengine Models

struct VolcFreeQuota: Codable {
    let pageNumber: Int?
    let pageSize: Int?
    let totalCount: Int?
    let items: [VolcModelItem]
}

struct VolcModelItem: Codable {
    let model: String?
    let displayName: String?
    let vendor: String?
    let state: String?
    let isOverdue: Bool?
    let freeUsage: VolcUsage?
    let resourcePacks: [VolcResourcePack]?

    var name: String {
        displayName ?? model ?? "未知模型"
    }

    var remaining: Double {
        if let value = freeUsage?.remaining { return value }
        if let packs = resourcePacks {
            let freePacks = packs.filter { $0.type == "FreeInference" }
            let selected = freePacks.isEmpty ? packs : freePacks
            return selected.compactMap(\.remaining).reduce(0, +)
        }
        return 0
    }

    var total: Double {
        if let value = freeUsage?.total { return value }
        if let packs = resourcePacks {
            let freePacks = packs.filter { $0.type == "FreeInference" }
            let selected = freePacks.isEmpty ? packs : freePacks
            return selected.compactMap(\.total).reduce(0, +)
        }
        return 0
    }

    var isAvailable: Bool {
        state == nil || state == "Available"
    }
}

struct VolcUsage: Codable {
    let total: Double?
    let consumed: Double?
    let remaining: Double?
}

struct VolcResourcePack: Codable {
    let type: String?
    let total: Double?
    let consumed: Double?
    let remaining: Double?
    let syncTime: String?
}

struct VolcSummary {
    let totalRemaining: Double
    let totalQuota: Double
    let modelsWithQuota: Int
    let totalModels: Int
    let topModels: [VolcModelItem]
    let lastUpdated: Date?
}

// MARK: - Codex Models

struct CodexUsageResponse: Codable {
    let planType: String?
    let rateLimit: CodexRateLimit?

    enum CodingKeys: String, CodingKey {
        case planType = "plan_type"
        case rateLimit = "rate_limit"
    }
}

struct CodexRateLimit: Codable {
    let allowed: Bool?
    let limitReached: Bool?
    let primaryWindow: CodexWindow?
    let secondaryWindow: CodexWindow?

    enum CodingKeys: String, CodingKey {
        case allowed
        case limitReached = "limit_reached"
        case primaryWindow = "primary_window"
        case secondaryWindow = "secondary_window"
    }
}

struct CodexWindow: Codable {
    let usedPercent: Double?
    let limitWindowSeconds: Int?
    let resetAfterSeconds: Int?
    let resetAt: TimeInterval?

    enum CodingKeys: String, CodingKey {
        case usedPercent = "used_percent"
        case limitWindowSeconds = "limit_window_seconds"
        case resetAfterSeconds = "reset_after_seconds"
        case resetAt = "reset_at"
    }

    var remainingPercent: Double {
        guard let u = usedPercent else { return 0 }
        return max(0, 100 - u)
    }

    var isWeekly: Bool {
        guard let s = limitWindowSeconds else { return false }
        return s >= 6 * 24 * 3600
    }

    var isFiveHour: Bool {
        guard let s = limitWindowSeconds else { return false }
        return s <= 6 * 3600
    }
}

struct CodexSummary {
    let planType: String
    let weeklyRemaining: Double?
    let weeklyResetAt: Date?
    let fiveHourRemaining: Double?
    let fiveHourResetAt: Date?
    let limitReached: Bool
    let lastUpdated: Date?
}

// MARK: - Balance level / color

enum BalanceLevel {
    case unknown
    case low
    case warning
    case medium
    case healthy

    var color: NSColor {
        switch self {
        case .low:     return .systemRed
        case .warning: return .systemOrange
        case .medium:  return .systemYellow
        case .healthy: return .systemGreen
        case .unknown: return .secondaryLabelColor
        }
    }

    var label: String {
        switch self {
        case .low:     return "余额偏低"
        case .warning: return "余额一般"
        case .medium:  return "余额充足"
        case .healthy: return "余额充裕"
        case .unknown: return "未知"
        }
    }
}

// MARK: - App Config

struct AppConfig: Codable {
    var provider: Provider
    var apiKey: String?
    var codexProxy: String?
    var deepSeekLastBalance: Double?
    var deepSeekScaleMax: Double?
    var refreshIntervalSeconds: Double?
    var enabledProviders: [Provider]?
    var selectedDeepSeekAccount: String?
    var useSystemProxy: Bool?
    var iconAppearance: IconAppearance?
    var autoDiscoverProviders: Bool?
    var qwenWorkspaceID: String?
    var providerCatalogVersion: Int?
    var geminiLoginConfirmed: Bool?
    var menuBarDisplayMode: MenuBarDisplayMode?
    var menuBarQuotaDisplayMode: MenuBarQuotaDisplayMode?

    enum CodingKeys: String, CodingKey {
        case provider
        case apiKey = "api_key"
        case codexProxy = "codex_proxy"
        case deepSeekLastBalance = "deepseek_last_balance"
        case deepSeekScaleMax = "deepseek_scale_max"
        case refreshIntervalSeconds = "refresh_interval_seconds"
        case enabledProviders = "enabled_providers"
        case selectedDeepSeekAccount = "selected_deepseek_account"
        case useSystemProxy = "use_system_proxy"
        case iconAppearance = "icon_appearance"
        case autoDiscoverProviders = "auto_discover_providers"
        case qwenWorkspaceID = "qwen_workspace_id"
        case providerCatalogVersion = "provider_catalog_version"
        case geminiLoginConfirmed = "gemini_login_confirmed"
        case menuBarDisplayMode = "menu_bar_display_mode"
        case menuBarQuotaDisplayMode = "menu_bar_quota_display_mode"
    }

    static func load(from url: URL) -> AppConfig {
        if let data = try? Data(contentsOf: url),
           let obj = try? JSONDecoder().decode(AppConfig.self, from: data) {
            return obj
        }
        // Legacy: only api_key
        if let data = try? Data(contentsOf: url),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let key = dict["api_key"] as? String {
            return AppConfig(
                provider: .deepseek,
                apiKey: key,
                codexProxy: nil,
                deepSeekLastBalance: nil,
                deepSeekScaleMax: nil,
                refreshIntervalSeconds: nil,
                enabledProviders: nil,
                selectedDeepSeekAccount: nil,
                useSystemProxy: nil,
                iconAppearance: nil,
                autoDiscoverProviders: nil
                , qwenWorkspaceID: nil
                , providerCatalogVersion: nil
                , geminiLoginConfirmed: nil
                , menuBarDisplayMode: nil
                , menuBarQuotaDisplayMode: nil
            )
        }
        return AppConfig(
            provider: .deepseek,
            apiKey: nil,
            codexProxy: nil,
            deepSeekLastBalance: nil,
            deepSeekScaleMax: nil,
            refreshIntervalSeconds: nil,
            enabledProviders: nil,
            selectedDeepSeekAccount: nil,
            useSystemProxy: nil,
            iconAppearance: nil,
            autoDiscoverProviders: nil
            , qwenWorkspaceID: nil
            , providerCatalogVersion: nil
            , geminiLoginConfirmed: nil
            , menuBarDisplayMode: nil
            , menuBarQuotaDisplayMode: nil
        )
    }

    func save(to url: URL) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let data = try? encoder.encode(self) {
            try? data.write(to: url, options: .atomic)
            try? FileManager.default.setAttributes(
                [.posixPermissions: 0o600],
                ofItemAtPath: url.path
            )
        }
    }
}

// MARK: - Proxy helper

struct ProxySettings {
    let host: String
    let port: Int
    let type: String // "socks5" or "http"

    static func parse(_ url: String) -> ProxySettings? {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let candidate = trimmed.contains("://") ? trimmed : "socks5://" + trimmed
        guard let components = URLComponents(string: candidate),
              let scheme = components.scheme?.lowercased(),
              ["socks5", "http", "https"].contains(scheme),
              let host = components.host?.trimmingCharacters(in: .whitespacesAndNewlines),
              !host.isEmpty,
              let port = components.port,
              (1...65_535).contains(port),
              components.user == nil,
              components.password == nil,
              (components.path.isEmpty || components.path == "/"),
              components.query == nil,
              components.fragment == nil else { return nil }
        return ProxySettings(host: host, port: port, type: scheme == "socks5" ? "socks5" : "http")
    }

    var connectionProxyDictionary: [String: Any] {
        if type == "socks5" {
            return [
                "SOCKSEnable": 1,
                "SOCKSProxy": host,
                "SOCKSPort": port
            ]
        } else {
            return [
                "HTTPEnable": 1,
                "HTTPProxy": host,
                "HTTPPort": port,
                "HTTPSEnable": 1,
                "HTTPSProxy": host,
                "HTTPSPort": port
            ]
        }
    }
}

struct ExternalQuotaSummary {
    let menuBarTitle: String
    let rows: [(String, String)]
    let fractionRemaining: Double?

    init(menuBarTitle: String, rows: [(String, String)], fractionRemaining: Double? = nil) {
        self.menuBarTitle = menuBarTitle
        self.rows = rows
        self.fractionRemaining = fractionRemaining
    }
}

// MARK: - Balance service

final class BalanceService {
    static let allowedRefreshIntervals: [TimeInterval] = [15, 30, 60, 120, 300]
    static let defaultRefreshInterval: TimeInterval = 120
    static let staleMinimumAge: TimeInterval = 300
    static let maximumLogSize: UInt64 = 512 * 1_024

    private enum FetchContext {
        @TaskLocal static var provider: Provider?
        @TaskLocal static var generation: Int?
    }

    // DeepSeek
    private(set) var dsBalance: DSBalanceInfo?
    private(set) var dsIsAvailable = false
    private(set) var dsScaleMax: Double?

    // Volcengine
    private(set) var volcSummary: VolcSummary?
    private(set) var volcPlanSummary: VolcPlanSummary?

    // Codex
    private(set) var codexSummary: CodexSummary?
    private(set) var externalSummary: ExternalQuotaSummary?
    private(set) var doubaoSummary: DoubaoQuotaSummary?

    // Common
    private(set) var provider: Provider
    private(set) var refreshIntervalSeconds: TimeInterval
    private(set) var enabledProviders: [Provider]
    private(set) var iconAppearance: IconAppearance
    private(set) var menuBarDisplayMode: MenuBarDisplayMode
    private(set) var menuBarQuotaDisplayMode: MenuBarQuotaDisplayMode
    private(set) var useSystemProxy: Bool
    private(set) var localProviderPath: String?
    private(set) var errorMessage: String?
    private(set) var lastUpdated: Date?
    private(set) var lastAttempted: Date?
    private(set) var isRefreshing = false
    private(set) var consecutiveFailures = 0

    var onUpdate: (() -> Void)?

    private let configDir: URL
    private let configURL: URL
    private var timer: Timer?
    private var refreshTask: Task<Void, Never>?
    private var refreshGeneration = 0
    private let arkcliPath: String

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        configDir = home.appendingPathComponent(".api-quota-dashboard", isDirectory: true)
        configURL = configDir.appendingPathComponent("config.json")

        let legacyConfigURL = home
            .appendingPathComponent(".deepseek-balance", isDirectory: true)
            .appendingPathComponent("config.json")
        try? FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)
        if !FileManager.default.fileExists(atPath: configURL.path),
           FileManager.default.fileExists(atPath: legacyConfigURL.path) {
            try? FileManager.default.copyItem(at: legacyConfigURL, to: configURL)
            try? FileManager.default.setAttributes(
                [.posixPermissions: 0o600],
                ofItemAtPath: configURL.path
            )
        }

        var cfg = AppConfig.load(from: configURL)

        if let legacyKey = cfg.apiKey?.trimmingCharacters(in: .whitespacesAndNewlines),
           !legacyKey.isEmpty,
           DeepSeekKeychain.accounts().isEmpty,
           DeepSeekKeychain.save(account: "默认账户", apiKey: legacyKey) {
            cfg.selectedDeepSeekAccount = "默认账户"
            cfg.apiKey = nil
        }

        // Older versions added locally installed apps even when they could not
        // provide quota data. Keep only providers this app can actually query.
        var providers = (cfg.enabledProviders ?? Provider.queryableCases)
            .filter { Self.isConfiguredForDisplay($0, config: cfg) }
        if (cfg.providerCatalogVersion ?? 0) < 5 {
            for provider in Provider.queryableCases
                where !provider.requiresAccountSetupForDisplay
                    && Self.isConfiguredForDisplay(provider, config: cfg)
                    && !providers.contains(provider) {
                providers.append(provider)
            }
            cfg.providerCatalogVersion = 5
        }
        if providers.isEmpty { providers = [.deepseek] }

        self.enabledProviders = providers
        self.provider = providers.contains(cfg.provider) ? cfg.provider : providers[0]
        self.dsScaleMax = cfg.deepSeekScaleMax
        self.refreshIntervalSeconds = Self.normalizedRefreshInterval(cfg.refreshIntervalSeconds)
        self.iconAppearance = cfg.iconAppearance ?? .system
        self.menuBarDisplayMode = cfg.menuBarDisplayMode ?? .valueOnly
        self.menuBarQuotaDisplayMode = cfg.menuBarQuotaDisplayMode ?? .all
        self.useSystemProxy = cfg.useSystemProxy ?? true
        cfg.provider = self.provider
        cfg.enabledProviders = providers
        cfg.iconAppearance = self.iconAppearance
        cfg.menuBarDisplayMode = self.menuBarDisplayMode
        cfg.menuBarQuotaDisplayMode = self.menuBarQuotaDisplayMode
        cfg.useSystemProxy = self.useSystemProxy
        cfg.autoDiscoverProviders = false
        cfg.save(to: configURL)

        // Locate arkcli
        if let envPath = ProcessInfo.processInfo.environment["PATH"] {
            let paths = envPath.split(separator: ":").map(String.init)
            var found = ""
            for p in paths {
                let candidate = (p as NSString).appendingPathComponent("arkcli")
                if FileManager.default.fileExists(atPath: candidate) {
                    found = candidate
                    break
                }
            }
            if found.isEmpty {
                let fallback = home.appendingPathComponent(".local/bin/arkcli").path
                if FileManager.default.fileExists(atPath: fallback) {
                    found = fallback
                }
            }
            self.arkcliPath = found
        } else {
            self.arkcliPath = home.appendingPathComponent(".local/bin/arkcli").path
        }

        requestRefresh(force: true)
        scheduleRefreshTimer()
    }

    deinit {
        timer?.invalidate()
        refreshTask?.cancel()
    }

    func setProvider(_ p: Provider) {
        guard enabledProviders.contains(p) else { return }
        if provider == p {
            requestRefresh(force: true)
            return
        }
        provider = p
        var cfg = AppConfig.load(from: configURL)
        cfg.provider = p
        cfg.save(to: configURL)
        dsBalance = nil
        volcSummary = nil
        volcPlanSummary = nil
        codexSummary = nil
        externalSummary = nil
        doubaoSummary = nil
        localProviderPath = nil
        errorMessage = nil
        lastUpdated = nil
        requestRefresh(force: true)
    }

    static func normalizedRefreshInterval(_ value: Double?) -> TimeInterval {
        guard let value, value >= 5, value <= 86_400 else {
            return defaultRefreshInterval
        }
        return value
    }

    func setRefreshInterval(_ seconds: TimeInterval) {
        let normalized = Self.normalizedRefreshInterval(seconds)
        refreshIntervalSeconds = normalized
        var cfg = AppConfig.load(from: configURL)
        cfg.refreshIntervalSeconds = normalized
        cfg.save(to: configURL)
        scheduleRefreshTimer()
        onUpdate?()
    }

    func setEnabledProviders(_ providers: [Provider]) {
        let available = providersAvailableForDisplay
        let unique = available.filter { providers.contains($0) }
        enabledProviders = unique.isEmpty ? [.deepseek] : unique
        if !enabledProviders.contains(provider) { provider = enabledProviders[0] }
        var cfg = AppConfig.load(from: configURL)
        cfg.enabledProviders = enabledProviders
        cfg.provider = provider
        cfg.save(to: configURL)
        onUpdate?()
        requestRefresh(force: true)
    }

    @discardableResult
    func discoverInstalledProviders() -> [LocalProviderDetection] {
        []
    }

    @discardableResult
    func saveDeepSeekAccount(name: String, apiKey: String) -> Bool {
        guard DeepSeekKeychain.save(account: name, apiKey: apiKey) else { return false }
        var cfg = AppConfig.load(from: configURL)
        cfg.selectedDeepSeekAccount = name.trimmingCharacters(in: .whitespacesAndNewlines)
        cfg.apiKey = nil
        cfg.save(to: configURL)
        if provider == .deepseek { requestRefresh(force: true) }
        onUpdate?()
        return true
    }

    func selectDeepSeekAccount(_ name: String) {
        guard DeepSeekKeychain.accounts().contains(name) else { return }
        var cfg = AppConfig.load(from: configURL)
        cfg.selectedDeepSeekAccount = name
        cfg.save(to: configURL)
        if provider == .deepseek { requestRefresh(force: true) }
        onUpdate?()
    }

    @discardableResult
    func deleteDeepSeekAccount(_ name: String) -> Bool {
        guard DeepSeekKeychain.delete(account: name) else { return false }
        var cfg = AppConfig.load(from: configURL)
        let remaining = DeepSeekKeychain.accounts()
        if cfg.selectedDeepSeekAccount == name { cfg.selectedDeepSeekAccount = remaining.first }
        cfg.save(to: configURL)
        if provider == .deepseek { requestRefresh(force: true) }
        onUpdate?()
        return true
    }

    @discardableResult
    func setProxyConfiguration(useSystem: Bool, manualProxy: String?) -> Bool {
        let trimmed = manualProxy?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let parsedProxy = trimmed.isEmpty ? nil : ProxySettings.parse(trimmed)
        if !useSystem, !trimmed.isEmpty, parsedProxy == nil { return false }
        useSystemProxy = useSystem
        var cfg = AppConfig.load(from: configURL)
        cfg.useSystemProxy = useSystem
        cfg.codexProxy = parsedProxy == nil ? nil : trimmed
        cfg.save(to: configURL)
        requestRefresh(force: true)
        onUpdate?()
        return true
    }

    func setIconAppearance(_ appearance: IconAppearance) {
        iconAppearance = appearance
        var cfg = AppConfig.load(from: configURL)
        cfg.iconAppearance = appearance
        cfg.save(to: configURL)
        onUpdate?()
    }

    func setMenuBarDisplayMode(_ mode: MenuBarDisplayMode) {
        menuBarDisplayMode = mode
        var cfg = AppConfig.load(from: configURL)
        cfg.menuBarDisplayMode = mode
        cfg.save(to: configURL)
        onUpdate?()
    }

    func setMenuBarQuotaDisplayMode(_ mode: MenuBarQuotaDisplayMode) {
        menuBarQuotaDisplayMode = mode
        var cfg = AppConfig.load(from: configURL)
        cfg.menuBarQuotaDisplayMode = mode
        cfg.save(to: configURL)
        onUpdate?()
    }

    private func scheduleRefreshTimer() {
        timer?.invalidate()
        timer = nil
        guard refreshIntervalSeconds > 0 else { return }

        timer = Timer.scheduledTimer(withTimeInterval: refreshIntervalSeconds, repeats: true) { [weak self] _ in
            self?.requestRefresh()
        }
        timer?.tolerance = min(refreshIntervalSeconds * 0.1, 30)
    }

    var apiKey: String {
        let cfg = AppConfig.load(from: configURL)
        if let account = cfg.selectedDeepSeekAccount,
           let key = DeepSeekKeychain.apiKey(account: account),
           !key.isEmpty {
            return key.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        var key = cfg.apiKey ?? ""
        if key.isEmpty {
            key = ProcessInfo.processInfo.environment["DEEPSEEK_API_KEY"] ?? ""
        }
        return key.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var codexProxy: String? {
        let cfg = AppConfig.load(from: configURL)
        return cfg.codexProxy
    }

    var selectedDeepSeekAccount: String? {
        AppConfig.load(from: configURL).selectedDeepSeekAccount
    }

    var deepSeekAccounts: [String] {
        DeepSeekKeychain.accounts()
    }

    var providersAvailableForDisplay: [Provider] {
        let cfg = AppConfig.load(from: configURL)
        return Provider.queryableCases.filter { Self.isConfiguredForDisplay($0, config: cfg) }
    }

    private static func isConfiguredForDisplay(_ provider: Provider, config: AppConfig) -> Bool {
        guard provider.supportsQuotaQuery else { return false }
        switch provider {
        case .claude, .kimi, .minimax, .openai, .openrouter, .siliconflow:
            return !(ProviderCredentialKeychain.apiKey(provider: provider) ?? "").isEmpty
        case .qwen:
            return !(ProviderCredentialKeychain.apiKey(provider: provider) ?? "").isEmpty
                && !(config.qwenWorkspaceID ?? "").isEmpty
        case .gemini:
            return config.geminiLoginConfirmed ?? false
        case .doubao:
            return ProviderDiscovery.scan().contains(where: { $0.provider == .doubao })
        case .zhipu:
            return ZhipuQuotaReader.hasChromeProfile
        default:
            return true
        }
    }

    func hasCredential(for provider: Provider) -> Bool {
        !(ProviderCredentialKeychain.apiKey(provider: provider) ?? "").isEmpty
    }

    @discardableResult
    func saveCredential(for provider: Provider, apiKey: String, workspaceID: String? = nil) -> Bool {
        guard ProviderCredentialKeychain.save(provider: provider, apiKey: apiKey) else { return false }
        if provider == .qwen {
            let workspace = workspaceID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !workspace.isEmpty else {
                _ = ProviderCredentialKeychain.delete(provider: provider)
                return false
            }
            var cfg = AppConfig.load(from: configURL)
            cfg.qwenWorkspaceID = workspace
            cfg.save(to: configURL)
        }
        if self.provider == provider { requestRefresh(force: true) }
        onUpdate?()
        return true
    }

    @discardableResult
    func deleteCredential(for provider: Provider) -> Bool {
        let deleted = ProviderCredentialKeychain.delete(provider: provider)
        if provider == .qwen {
            var cfg = AppConfig.load(from: configURL)
            cfg.qwenWorkspaceID = nil
            cfg.save(to: configURL)
        }
        setEnabledProviders(enabledProviders.filter { $0 != provider })
        onUpdate?()
        return deleted
    }

    func setGeminiLoginConfirmed(_ confirmed: Bool) {
        var cfg = AppConfig.load(from: configURL)
        cfg.geminiLoginConfirmed = confirmed
        cfg.save(to: configURL)
        if !confirmed {
            setEnabledProviders(enabledProviders.filter { $0 != .gemini })
        } else {
            onUpdate?()
        }
    }

    var isGeminiLoginConfirmed: Bool {
        AppConfig.load(from: configURL).geminiLoginConfirmed ?? false
    }

    var qwenWorkspaceID: String? {
        AppConfig.load(from: configURL).qwenWorkspaceID
    }

    private func configuredURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        if useSystemProxy,
           let settings = CFNetworkCopySystemProxySettings()?.takeRetainedValue() as? [AnyHashable: Any] {
            configuration.connectionProxyDictionary = settings
        } else if let proxyString = codexProxy,
                  !proxyString.isEmpty,
                  let proxy = ProxySettings.parse(proxyString) {
            configuration.connectionProxyDictionary = proxy.connectionProxyDictionary
        }
        return URLSession(configuration: configuration)
    }

    // MARK: - Computed display properties

    var menuBarTitle: String {
        switch provider {
        case .deepseek:
            if let b = dsBalance { return b.totalBalance }
            if errorMessage != nil { return "!" }
            return "…"
        case .volcengine:
            if let pct = volcPlanSummary?.primaryPeriod?.remainingPercent {
                return String(format: "%.0f%%", pct)
            }
            if let s = volcSummary { return formatTokens(s.totalRemaining) }
            if errorMessage != nil { return "!" }
            return "…"
        case .codex:
            if let s = codexSummary, let pct = s.weeklyRemaining {
                return String(format: "%.0f%%", pct)
            }
            if errorMessage != nil { return "!" }
            return "…"
        case .claude, .kimi, .qwen, .minimax, .openai, .openrouter, .siliconflow, .zhipu:
            if let summary = externalSummary { return summary.menuBarTitle }
            if errorMessage != nil { return "!" }
            return "…"
        case .gemini:
            return "网页登录"
        case .doubao:
            if let summary = doubaoSummary { return summary.menuBarTitle }
            if errorMessage != nil { return "!" }
            return "…"
        case .wenxin, .hunyuan:
            return localProviderPath == nil ? "未找到" : "已安装"
        }
    }

    static func quotaLineValues(
        total: String?,
        fiveHour: String?,
        mode: MenuBarQuotaDisplayMode
    ) -> [String] {
        switch mode {
        case .fiveHourOnly:
            return [fiveHour ?? total].compactMap { $0 }
        case .totalOnly:
            return [total ?? fiveHour].compactMap { $0 }
        case .all:
            return [total, fiveHour].compactMap { $0 }
        }
    }

    private var quotaDisplayLines: [MenuBarDisplayLine] {
        let total: MenuBarDisplayLine?
        let fiveHour: MenuBarDisplayLine?

        switch provider {
        case .codex:
            total = codexSummary?.weeklyRemaining.map {
                MenuBarDisplayLine(text: String(format: "%.0f%%", $0), percentage: $0)
            }
            fiveHour = codexSummary?.fiveHourRemaining.map {
                MenuBarDisplayLine(text: String(format: "%.0f%%", $0), percentage: $0, horizontalOffset: 0.5)
            }
        case .volcengine:
            let periods = volcPlanSummary?.primaryItem?.periods ?? []
            let totalPeriod = periods.first(where: { $0.label == "weekly" })
                ?? periods.first(where: { $0.label == "monthly" })
                ?? periods.first(where: { $0.label == "session" })
                ?? periods.first(where: { $0.label != "5h" })
            total = totalPeriod?.remainingPercent.map {
                MenuBarDisplayLine(text: String(format: "%.0f%%", $0), percentage: $0)
            } ?? volcSummary.map {
                MenuBarDisplayLine(text: formatTokens($0.totalRemaining), percentage: nil)
            }
            fiveHour = periods.first(where: { $0.label == "5h" })?.remainingPercent
                .map { MenuBarDisplayLine(text: String(format: "%.0f%%", $0), percentage: $0, horizontalOffset: 0.5) }
        case .doubao:
            total = doubaoSummary.map {
                MenuBarDisplayLine(text: $0.lastSevenDays, percentage: $0.lastSevenDaysRemaining)
            }
            fiveHour = doubaoSummary.map {
                MenuBarDisplayLine(text: $0.currentPeriod, percentage: $0.currentPeriodRemaining, horizontalOffset: 0.5)
            }
        default:
            total = MenuBarDisplayLine(text: menuBarTitle, percentage: nil)
            fiveHour = nil
        }

        switch menuBarQuotaDisplayMode {
        case .fiveHourOnly:
            return [fiveHour ?? total].compactMap { $0 }
        case .totalOnly:
            return [total ?? fiveHour].compactMap { $0 }
        case .all:
            return [total, fiveHour].compactMap { $0 }
        }
    }

    var displayedMenuBarLineModels: [MenuBarDisplayLine] {
        var lines = quotaDisplayLines
        if lines.isEmpty {
            lines = [MenuBarDisplayLine(text: menuBarTitle, percentage: nil)]
        }
        if menuBarDisplayMode == .providerAndValue, !lines.isEmpty {
            lines[0].text = provider.shortName + " " + lines[0].text
        }
        return lines
    }

    var displayedMenuBarLines: [String] {
        displayedMenuBarLineModels.map(\.text)
    }

    var displayedMenuBarTitle: String {
        displayedMenuBarLines.joined(separator: "\n")
    }

    var hasFiveHourQuota: Bool {
        Self.hasFiveHourQuota(
            provider: provider,
            codexSummary: codexSummary,
            volcPlanSummary: volcPlanSummary,
            doubaoSummary: doubaoSummary
        )
    }

    static func hasFiveHourQuota(
        provider: Provider,
        codexSummary: CodexSummary?,
        volcPlanSummary: VolcPlanSummary?,
        doubaoSummary: DoubaoQuotaSummary? = nil
    ) -> Bool {
        switch provider {
        case .codex:
            return codexSummary?.fiveHourRemaining != nil || codexSummary?.fiveHourResetAt != nil
        case .volcengine:
            return volcPlanSummary?.primaryItem?.periods.contains(where: { $0.label == "5h" }) == true
        case .doubao:
            return doubaoSummary != nil
        default:
            return false
        }
    }

    var isDataStale: Bool {
        guard let lastUpdated else { return false }
        let staleAge = max(Self.staleMinimumAge, refreshIntervalSeconds * 2.5)
        return Date().timeIntervalSince(lastUpdated) > staleAge
    }

    var freshnessDescription: String {
        if isRefreshing {
            guard let lastUpdated else { return "正在首次刷新…" }
            return "正在刷新 · 上次" + Self.relativeAgeDescription(since: lastUpdated)
        }
        guard let lastUpdated else {
            return errorMessage == nil ? "尚未完成刷新" : "刷新失败"
        }
        let age = Self.relativeAgeDescription(since: lastUpdated)
        return isDataStale ? "⚠ 数据可能已过期 · " + age : "更新于" + age
    }

    static func relativeAgeDescription(since date: Date, now: Date = Date()) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(date)))
        switch seconds {
        case 0..<5: return "刚刚"
        case 5..<60: return "\(seconds) 秒前"
        case 60..<3_600: return "\(seconds / 60) 分钟前"
        case 3_600..<86_400: return "\(seconds / 3_600) 小时前"
        default: return "\(seconds / 86_400) 天前"
        }
    }

    var currentSummaryRows: [(String, String)] {
        switch provider {
        case .deepseek:
            guard let balance = dsBalance else { return [] }
            let currency = symbol(for: balance.currency)
            return [
                ("总余额", currency + balance.totalBalance),
                ("充值余额", currency + balance.toppedUpBalance),
                ("赠送余额", currency + balance.grantedBalance)
            ]
        case .volcengine:
            if let period = volcPlanSummary?.primaryPeriod,
               let remaining = period.remainingPercent {
                return [("订阅剩余", String(format: "%.0f%%", remaining))]
            }
            guard let summary = volcSummary else { return [] }
            return [
                ("剩余总额度", formatTokens(summary.totalRemaining) + " tokens"),
                ("有额度模型", "\(summary.modelsWithQuota) / \(summary.totalModels) 个")
            ]
        case .codex:
            guard let summary = codexSummary else { return [] }
            return [
                ("每周剩余", summary.weeklyRemaining.map { String(format: "%.0f%%", $0) } ?? "未知"),
                ("5 小时剩余", summary.fiveHourRemaining.map { String(format: "%.0f%%", $0) } ?? "未知")
            ]
        case .claude, .gemini, .kimi, .qwen, .minimax, .openai, .openrouter, .siliconflow, .zhipu:
            return externalSummary?.rows ?? []
        case .doubao:
            return doubaoSummary?.rows ?? []
        case .wenxin, .hunyuan:
            return [("本机状态", localProviderPath == nil ? "未检测到" : "已安装")]
        }
    }

    var currentSummaryText: String {
        var lines = [provider.displayName, "菜单栏：" + menuBarTitle]
        lines.append(contentsOf: currentSummaryRows.map { "\($0.0)：\($0.1)" })
        if let errorMessage { lines.append("状态：" + Self.sanitizedErrorMessage(errorMessage)) }
        lines.append(freshnessDescription)
        return lines.joined(separator: "\n")
    }

    var diagnosticReport: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "开发构建"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "-"
        let credentialState: String
        if provider == .deepseek {
            credentialState = apiKey.isEmpty ? "未配置" : "已配置"
        } else if provider.requiresAccountSetupForDisplay && provider != .gemini {
            credentialState = hasCredential(for: provider) ? "已配置" : "未配置"
        } else {
            credentialState = "不适用"
        }
        return [
            "API 额度看板 \(version) (\(build))",
            "macOS \(ProcessInfo.processInfo.operatingSystemVersionString)",
            "提供方：\(provider.displayName)",
            "刷新：\(isRefreshing ? "进行中" : "空闲")，间隔 \(Int(refreshIntervalSeconds)) 秒",
            "连续失败：\(consecutiveFailures)",
            "凭证：\(credentialState)（不包含密钥内容）",
            "代理：\(useSystemProxy ? "系统" : (codexProxy == nil ? "直连" : "手动"))",
            "数据：\(freshnessDescription)",
            "最近错误：\(errorMessage.map(Self.sanitizedErrorMessage) ?? "无")"
        ].joined(separator: "\n")
    }

    // MARK: - Discrete quota colors (red → green, exactly 10 steps)

    static func tenStepIndex(value: Double, max: Double) -> Int {
        guard max > 0 else { return 0 }
        let ratio = Swift.max(0, Swift.min(value / max, 1))
        return Swift.min(9, Int(floor(ratio * 10)))
    }

    /// 将 0...max 离散映射为 10 档颜色：第 1 档红色，第 10 档绿色。
    static func tenStepColor(value: Double, max: Double) -> NSColor {
        let stepIndex = tenStepIndex(value: value, max: max)
        let hue = CGFloat(stepIndex) / 9.0 * (120.0 / 360.0)
        return NSColor(hue: hue, saturation: 0.85, brightness: 0.92, alpha: 1.0)
    }

    static func updatedDeepSeekScale(current: Double, previous: Double?, scaleMax: Double?) -> Double? {
        guard current > 0 else { return scaleMax }
        if previous == nil || current > (previous ?? current) + 0.0001 || (scaleMax ?? 0) <= 0 {
            return current
        }
        return scaleMax
    }

    /// DeepSeek: 余额增加时以新余额重设十档基准，随后随消耗逐档由绿转红。
    var dsColor: NSColor {
        guard errorMessage == nil, let b = dsBalance, let v = Double(b.totalBalance) else { return .secondaryLabelColor }
        guard let scaleMax = dsScaleMax, scaleMax > 0 else { return .systemRed }
        return BalanceService.tenStepColor(value: v, max: scaleMax)
    }

    var dsStep: Int {
        guard let b = dsBalance,
              let value = Double(b.totalBalance),
              let scaleMax = dsScaleMax,
              scaleMax > 0 else { return 1 }
        return BalanceService.tenStepIndex(value: value, max: scaleMax) + 1
    }

    /// Codex/OpenAI: 0–100% 十档渐变
    var codexColor: NSColor {
        guard errorMessage == nil, let s = codexSummary, let pct = s.weeklyRemaining else { return .secondaryLabelColor }
        return BalanceService.tenStepColor(value: pct, max: 100)
    }

    var menuBarColor: NSColor {
        if isDataStale { return .systemOrange }
        switch provider {
        case .deepseek: return dsColor
        case .volcengine: return volcLevel.color
        case .codex: return codexColor
        case .claude, .kimi, .qwen, .minimax, .openai, .openrouter, .siliconflow, .zhipu:
            return errorMessage == nil && externalSummary != nil ? .systemGreen : .secondaryLabelColor
        case .gemini:
            return .systemBlue
        case .doubao:
            return errorMessage == nil && doubaoSummary != nil ? .systemGreen : .secondaryLabelColor
        case .wenxin, .hunyuan:
            return localProviderPath == nil ? .secondaryLabelColor : .systemGreen
        }
    }

    var dsLevel: BalanceLevel {
        guard errorMessage == nil, dsBalance != nil else { return .unknown }
        guard let v = Double(dsBalance!.totalBalance) else { return .unknown }
        switch v {
        case ..<2.0:  return .low
        case ..<4.0:  return .warning
        case ..<8.0:  return .medium
        default:      return .healthy
        }
    }

    var volcLevel: BalanceLevel {
        if let remaining = volcPlanSummary?.primaryPeriod?.remainingPercent {
            switch remaining {
            case ..<10: return .low
            case ..<30: return .warning
            case ..<60: return .medium
            default: return .healthy
            }
        }
        guard errorMessage == nil, let s = volcSummary else { return .unknown }
        guard s.totalQuota > 0 else { return .low }
        let pct = Double(s.totalRemaining) / Double(s.totalQuota)
        switch pct {
        case ..<0.1:  return .low
        case ..<0.3:  return .warning
        case ..<0.6:  return .medium
        default:      return .healthy
        }
    }

    var codexLevel: BalanceLevel {
        guard errorMessage == nil, let s = codexSummary, let pct = s.weeklyRemaining else { return .unknown }
        switch pct {
        case ..<10:  return .low
        case ..<30:  return .warning
        case ..<60:  return .medium
        default:     return .healthy
        }
    }

    func symbol(for currency: String) -> String {
        switch currency.uppercased() {
        case "CNY": return "¥"
        case "USD": return "$"
        default:    return currency + " "
        }
    }

    func formatTokens(_ n: Double) -> String {
        if abs(n) >= 1_000_000_000 {
            return String(format: "%.1fB", n / 1_000_000_000)
        } else if abs(n) >= 1_000_000 {
            return String(format: "%.1fM", n / 1_000_000)
        } else if abs(n) >= 1_000 {
            return String(format: "%.0fK", n / 1_000)
        }
        return String(format: "%.0f", n)
    }

    func refresh() { requestRefresh(force: true) }

    func refreshIfStale() {
        guard !isRefreshing else { return }
        guard lastUpdated == nil || isDataStale else { return }
        requestRefresh()
    }

    static func shouldStartRefresh(isRefreshing: Bool, force: Bool) -> Bool {
        !isRefreshing || force
    }

    static func shouldApplyFetchResult(
        requestedProvider: Provider,
        currentProvider: Provider,
        generation: Int,
        currentGeneration: Int
    ) -> Bool {
        requestedProvider == currentProvider && generation == currentGeneration
    }

    private func requestRefresh(force: Bool = false) {
        guard Self.shouldStartRefresh(isRefreshing: isRefreshing, force: force) else { return }
        if force { refreshTask?.cancel() }

        refreshGeneration += 1
        let generation = refreshGeneration
        let requestedProvider = provider
        isRefreshing = true
        lastAttempted = Date()
        onUpdate?()

        refreshTask = Task { [weak self] in
            guard let self else { return }
            await FetchContext.$provider.withValue(requestedProvider) {
                await FetchContext.$generation.withValue(generation) {
                    await self.fetch(requestedProvider)
                }
            }
            await MainActor.run {
                guard Self.shouldApplyFetchResult(
                    requestedProvider: requestedProvider,
                    currentProvider: self.provider,
                    generation: generation,
                    currentGeneration: self.refreshGeneration
                ) else { return }
                self.isRefreshing = false
                self.consecutiveFailures = self.errorMessage == nil ? 0 : self.consecutiveFailures + 1
                self.onUpdate?()
            }
        }
    }

    // MARK: - Fetch dispatcher

    private func fetch(_ requestedProvider: Provider) async {
        switch requestedProvider {
        case .deepseek: await fetchDeepSeek()
        case .volcengine: await fetchVolcengine()
        case .codex: await fetchCodex()
        case .kimi: await fetchKimi()
        case .qwen: await fetchQwen()
        case .minimax: await fetchMiniMax()
        case .claude: await fetchClaude()
        case .openai: await fetchOpenAI()
        case .openrouter: await fetchOpenRouter()
        case .siliconflow: await fetchSiliconFlow()
        case .doubao: await fetchDoubao()
        case .zhipu: await fetchZhipu()
        case .gemini:
            await setState {
                self.externalSummary = ExternalQuotaSummary(
                    menuBarTitle: "网页登录",
                    rows: [("查询方式", "登录 Google AI Studio → Usage / Billing")]
                )
                self.errorMessage = nil
                self.lastUpdated = Date()
            }
        case .wenxin, .hunyuan:
            await fetchLocalProvider()
        }
    }

    private func fetchZhipu() async {
        do {
            let summary = try await ZhipuQuotaReader.fetch(session: configuredURLSession())
            await setState {
                self.externalSummary = ExternalQuotaSummary(
                    menuBarTitle: summary.menuBarTitle,
                    rows: summary.rows,
                    fractionRemaining: summary.fractionRemaining
                )
                self.errorMessage = nil
                self.lastUpdated = Date()
            }
        } catch {
            await setState {
                self.externalSummary = nil
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func fetchDoubao() async {
        do {
            let summary = try await DoubaoQuotaReader.fetch(session: configuredURLSession())
            await setState {
                self.doubaoSummary = summary
                self.localProviderPath = ProviderDiscovery.scan()
                    .first(where: { $0.provider == .doubao })?.path
                self.errorMessage = nil
                self.lastUpdated = Date()
            }
        } catch {
            await setState {
                self.doubaoSummary = nil
                self.localProviderPath = ProviderDiscovery.scan()
                    .first(where: { $0.provider == .doubao })?.path
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func fetchLocalProvider() async {
        let detection = ProviderDiscovery.scan().first(where: { $0.provider == provider })
        await setState {
            self.localProviderPath = detection?.path
            self.errorMessage = nil
            self.lastUpdated = Date()
        }
    }

    // MARK: - DeepSeek fetch

    private func fetchDeepSeek() async {
        let key = apiKey
        guard !key.isEmpty else {
            await setState { self.errorMessage = "未配置 API Key，请在设置的“账号”中添加" }
            log("DS: no api key")
            return
        }

        guard let url = URL(string: "https://api.deepseek.com/user/balance") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("Bearer " + key, forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.timeoutInterval = 15

        do {
            let (data, _) = try await performRequest(req)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let decoded = try decoder.decode(DSBalanceResponse.self, from: data)
            let info = decoded.balanceInfos.first

            var newScaleMax = dsScaleMax
            if let info, let current = Double(info.totalBalance) {
                var cfg = AppConfig.load(from: configURL)
                let previous = cfg.deepSeekLastBalance

                // 余额增加通常意味着充值：以增加后的当前余额重设十档基准。
                newScaleMax = Self.updatedDeepSeekScale(
                    current: current,
                    previous: previous,
                    scaleMax: cfg.deepSeekScaleMax
                )
                cfg.deepSeekScaleMax = newScaleMax
                cfg.deepSeekLastBalance = current
                cfg.save(to: configURL)
            }

            await setState {
                self.dsBalance = info
                self.dsIsAvailable = decoded.isAvailable
                self.dsScaleMax = newScaleMax
                self.errorMessage = nil
                self.lastUpdated = Date()
            }
            if let b = info {
                log("DS ok " + b.currency + " total=" + b.totalBalance)
            }
        } catch {
            let msg = Self.sanitizedErrorMessage(error.localizedDescription)
            await setState { self.errorMessage = msg }
            log("DS error " + msg)
        }
    }

    // MARK: - Volcengine fetch

    private func runArkcli(arguments: [String], skill: String) throws -> Data {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: arkcliPath)
        process.arguments = arguments

        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        env["HOME"] = FileManager.default.homeDirectoryForCurrentUser.path
        env["ARKCLI_CALLER_TYPE"] = "ai_agent"
        env["ARKCLI_CALLER_NAME"] = "balance_menubar"
        env["ARKCLI_SKILL_NAME"] = skill
        process.environment = env

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        try process.run()
        process.waitUntilExit()

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        guard process.terminationStatus == 0 else {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: errorData, encoding: .utf8) ?? "arkcli exited with code \(process.terminationStatus)"
            throw NSError(
                domain: "APIQuotaDashboard.arkcli",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: message]
            )
        }
        return data
    }

    func loadVolcProfiles(completion: @escaping (Result<VolcProfileList, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let result: Result<VolcProfileList, Error>
            do {
                let data = try self.runArkcli(
                    arguments: ["profile", "list", "--format", "json"],
                    skill: "arkcli-profile"
                )
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                result = .success(try decoder.decode(VolcProfileList.self, from: data))
            } catch {
                result = .failure(error)
            }
            DispatchQueue.main.async { completion(result) }
        }
    }

    func switchVolcProfile(_ name: String, completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let result: Result<Void, Error>
            do {
                _ = try self.runArkcli(
                    arguments: ["profile", "use", name, "--format", "json"],
                    skill: "arkcli-profile"
                )
                result = .success(())
            } catch {
                result = .failure(error)
            }
            DispatchQueue.main.async {
                completion(result)
                if case .success = result, self.provider == .volcengine {
                    self.requestRefresh(force: true)
                }
            }
        }
    }

    func loginVolc(completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let result: Result<Void, Error>
            do {
                _ = try self.runArkcli(
                    arguments: ["auth", "login", "volc-sso"],
                    skill: "arkcli-auth"
                )
                result = .success(())
            } catch {
                result = .failure(error)
            }
            DispatchQueue.main.async {
                completion(result)
                if case .success = result, self.provider == .volcengine {
                    self.requestRefresh(force: true)
                }
            }
        }
    }

    private func fetchVolcengine() async {
        guard !arkcliPath.isEmpty, FileManager.default.fileExists(atPath: arkcliPath) else {
            await setState { self.errorMessage = "未找到 arkcli，请先安装：npm i -g @volcengine/ark-cli" }
            log("Volc: arkcli not found")
            return
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        var planSummary: VolcPlanSummary?

        do {
            let data = try runArkcli(
                arguments: ["usage", "plan", "--format", "json"],
                skill: "arkcli-usage"
            )
            let response = try decoder.decode(VolcPlanResponse.self, from: data)
            let subscribed = response.items.filter { $0.subscribed && !$0.periods.isEmpty }
            if !subscribed.isEmpty { planSummary = VolcPlanSummary(items: subscribed) }
        } catch {
            log("Volc plan unavailable: " + Self.sanitizedErrorMessage(error.localizedDescription))
        }

        do {
            let data = try runArkcli(
                arguments: ["usage", "balance", "--type", "free-quota", "--page-size", "50", "--format", "json"],
                skill: "arkcli-usage"
            )
            let quota = try decoder.decode(VolcFreeQuota.self, from: data)

            var totalRemaining = 0.0
            var totalQuota = 0.0
            var modelsWithQuota = 0
            for item in quota.items {
                let rem = item.remaining
                let tot = item.total
                totalRemaining += rem
                totalQuota += tot
                if rem > 0 { modelsWithQuota += 1 }
            }

            // state=Unavailable 只代表当前不可推理，不代表免费额度行无效。
            let sorted = quota.items.sorted { $0.remaining > $1.remaining }
            let topModels = Array(sorted.prefix(8))

            let summary = VolcSummary(
                totalRemaining: totalRemaining,
                totalQuota: totalQuota,
                modelsWithQuota: modelsWithQuota,
                totalModels: quota.totalCount ?? quota.items.count,
                topModels: topModels,
                lastUpdated: Date()
            )

            await setState {
                self.volcSummary = summary
                self.volcPlanSummary = planSummary
                self.errorMessage = nil
                self.lastUpdated = Date()
            }
            let planCount = planSummary?.items.count ?? 0
            log("Volc ok: plans=\(planCount), totalRemaining=\(totalRemaining), modelsWithQuota=\(modelsWithQuota)/\(quota.totalCount ?? quota.items.count)")
        } catch {
            let msg = Self.sanitizedErrorMessage(error.localizedDescription)
            if let planSummary {
                await setState {
                    self.volcPlanSummary = planSummary
                    self.volcSummary = nil
                    self.errorMessage = nil
                    self.lastUpdated = Date()
                }
                log("Volc plan ok, free quota unavailable: " + msg.prefix(200))
                return
            }
            await setState {
                self.volcPlanSummary = nil
                self.errorMessage = msg
            }
            log("Volc error: " + msg)
        }
    }

    // MARK: - Codex fetch

    private func fetchCodex() async {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let authURL = home.appendingPathComponent(".codex").appendingPathComponent("auth.json")

        guard let authData = try? Data(contentsOf: authURL),
              let authObj = try? JSONSerialization.jsonObject(with: authData) as? [String: Any],
              let tokens = authObj["tokens"] as? [String: Any],
              let accessToken = tokens["access_token"] as? String,
              let accountId = tokens["account_id"] as? String else {
            await setState { self.errorMessage = "未找到 Codex 登录凭证 (~/.codex/auth.json)" }
            log("Codex: no auth")
            return
        }

        guard let url = URL(string: "https://chatgpt.com/backend-api/wham/usage") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
        req.setValue(accountId, forHTTPHeaderField: "ChatGPT-Account-Id")
        req.setValue("https://chatgpt.com", forHTTPHeaderField: "Origin")
        req.setValue("https://chatgpt.com/", forHTTPHeaderField: "Referer")
        req.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.timeoutInterval = 20

        do {
            let (data, _) = try await performRequest(req)

            let decoder = JSONDecoder()
            let decoded = try decoder.decode(CodexUsageResponse.self, from: data)

            // Parse windows
            var weeklyRemaining: Double? = nil
            var weeklyResetAt: Date? = nil
            var fiveHourRemaining: Double? = nil
            var fiveHourResetAt: Date? = nil

            if let rl = decoded.rateLimit {
                if let pw = rl.primaryWindow {
                    if pw.isWeekly {
                        weeklyRemaining = pw.remainingPercent
                        if let ra = pw.resetAt { weeklyResetAt = Date(timeIntervalSince1970: ra) }
                    } else if pw.isFiveHour {
                        fiveHourRemaining = pw.remainingPercent
                        if let ra = pw.resetAt { fiveHourResetAt = Date(timeIntervalSince1970: ra) }
                    } else {
                        // Default: treat as weekly
                        weeklyRemaining = pw.remainingPercent
                        if let ra = pw.resetAt { weeklyResetAt = Date(timeIntervalSince1970: ra) }
                    }
                }
                if let sw = rl.secondaryWindow {
                    if sw.isWeekly {
                        weeklyRemaining = sw.remainingPercent
                        if let ra = sw.resetAt { weeklyResetAt = Date(timeIntervalSince1970: ra) }
                    } else if sw.isFiveHour {
                        fiveHourRemaining = sw.remainingPercent
                        if let ra = sw.resetAt { fiveHourResetAt = Date(timeIntervalSince1970: ra) }
                    }
                }
            }

            let summary = CodexSummary(
                planType: decoded.planType ?? "unknown",
                weeklyRemaining: weeklyRemaining,
                weeklyResetAt: weeklyResetAt,
                fiveHourRemaining: fiveHourRemaining,
                fiveHourResetAt: fiveHourResetAt,
                limitReached: decoded.rateLimit?.limitReached ?? false,
                lastUpdated: Date()
            )

            await setState {
                self.codexSummary = summary
                self.errorMessage = nil
                self.lastUpdated = Date()
            }
            log("Codex ok: plan=\(summary.planType) weekly=\(weeklyRemaining ?? -1)% 5h=\(fiveHourRemaining ?? -1)%")
        } catch {
            let msg = Self.sanitizedErrorMessage(error.localizedDescription)
            await setState { self.errorMessage = msg }
            log("Codex error: " + msg)
        }
    }

    // MARK: - API-key providers

    private func credential(for provider: Provider) async -> String? {
        let key = ProviderCredentialKeychain.apiKey(provider: provider)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !key.isEmpty else {
            await setState {
                self.externalSummary = nil
                self.errorMessage = "尚未配置 \(provider.displayName) 凭证，请在设置的“账号”中添加"
            }
            return nil
        }
        return key
    }

    private func fetchKimi() async {
        guard let key = await credential(for: .kimi),
              let url = URL(string: "https://api.moonshot.cn/v1/users/me/balance") else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer " + key, forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 15
        do {
            let (data, _) = try await performRequest(request)
            guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let values = root["data"] as? [String: Any],
                  let available = number(values["available_balance"]) else {
                throw queryError("Kimi 返回数据缺少可用余额")
            }
            let cash = number(values["cash_balance"]) ?? 0
            let voucher = number(values["voucher_balance"]) ?? 0
            await setExternalSummary(
                title: String(format: "%.2f", available),
                rows: [
                    ("可用余额", String(format: "¥%.2f", available)),
                    ("现金余额", String(format: "¥%.2f", cash)),
                    ("代金券余额", String(format: "¥%.2f", voucher))
                ]
            )
        } catch { await setExternalError(.kimi, error) }
    }

    private func fetchQwen() async {
        guard let key = await credential(for: .qwen) else { return }
        let workspace = qwenWorkspaceID?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !workspace.isEmpty else {
            await setState { self.errorMessage = "尚未配置通义千问 Workspace ID" }
            return
        }
        guard let url = URL(string: "https://\(workspace).cn-beijing.maas.aliyuncs.com/api/v1/models/limits?page_no=1&page_size=100") else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer " + key, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20
        do {
            let (data, _) = try await performRequest(request)
            guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let output = root["output"] as? [String: Any],
                  let quotas = output["quotas"] as? [[String: Any]] else {
                throw queryError("通义千问返回数据缺少模型限额")
            }
            var rows: [(String, String)] = [("可查询模型", "\(quotas.count) 个")]
            for quota in quotas.prefix(7) {
                let model = quota["model"] as? String ?? "未知模型"
                let limit = quota["workspace_limit"] as? [String: Any]
                    ?? quota["model_limit"] as? [String: Any]
                if let usage = number(limit?["usage_limit"]) {
                    rows.append((model, formatTokens(usage) + " tokens"))
                } else if let requestLimit = number(limit?["request_limit"]) {
                    rows.append((model, String(format: "%.0f 次/周期", requestLimit)))
                }
            }
            await setExternalSummary(title: "\(quotas.count)模", rows: rows)
        } catch { await setExternalError(.qwen, error) }
    }

    private func fetchMiniMax() async {
        guard let key = await credential(for: .minimax),
              let url = URL(string: "https://www.minimaxi.com/v1/token_plan/remains") else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer " + key, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20
        do {
            let (data, _) = try await performRequest(request)
            let object = try JSONSerialization.jsonObject(with: data)
            let scalars = flattenedScalars(object).filter { !$0.0.lowercased().contains("key") }
            guard !scalars.isEmpty else { throw queryError("MiniMax 返回了空的套餐信息") }
            let rows = Array(scalars.prefix(8)).map { (readableJSONPath($0.0), $0.1) }
            let primary = scalars.first(where: {
                let key = $0.0.lowercased()
                return key.contains("remain") || key.contains("left") || key.contains("percent")
            })?.1 ?? "已查询"
            await setExternalSummary(title: String(primary.prefix(8)), rows: rows)
        } catch { await setExternalError(.minimax, error) }
    }

    private func fetchClaude() async {
        guard let key = await credential(for: .claude) else { return }
        let formatter = ISO8601DateFormatter()
        let ending = Date()
        let starting = Calendar.current.date(byAdding: .day, value: -7, to: ending) ?? ending
        var components = URLComponents(string: "https://api.anthropic.com/v1/organizations/usage_report/messages")
        components?.queryItems = [
            URLQueryItem(name: "starting_at", value: formatter.string(from: starting)),
            URLQueryItem(name: "ending_at", value: formatter.string(from: ending)),
            URLQueryItem(name: "bucket_width", value: "1d")
        ]
        guard let url = components?.url else { return }
        var request = URLRequest(url: url)
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 20
        do {
            let (data, _) = try await performRequest(request)
            let object = try JSONSerialization.jsonObject(with: data)
            let tokenValues = flattenedNumbers(object).filter { $0.0.lowercased().contains("token") }
            let total = tokenValues.reduce(0) { $0 + $1.1 }
            let rows: [(String, String)] = [
                ("统计范围", "最近 7 天组织 API 用量"),
                ("Token 合计", formatTokens(total))
            ]
            await setExternalSummary(title: formatTokens(total), rows: rows)
        } catch { await setExternalError(.claude, error) }
    }

    private func fetchOpenAI() async {
        guard let key = await credential(for: .openai) else { return }
        let startTime = Int(Date().addingTimeInterval(-30 * 24 * 60 * 60).timeIntervalSince1970)
        var components = URLComponents(string: "https://api.openai.com/v1/organization/costs")
        components?.queryItems = [
            URLQueryItem(name: "start_time", value: String(startTime)),
            URLQueryItem(name: "bucket_width", value: "1d"),
            URLQueryItem(name: "limit", value: "30")
        ]
        guard let url = components?.url else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer " + key, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 20
        do {
            let (data, _) = try await performRequest(request)
            guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let buckets = root["data"] as? [[String: Any]] else {
                throw queryError("OpenAI 返回数据缺少成本明细")
            }
            var costsByCurrency: [String: Double] = [:]
            for bucket in buckets {
                for result in bucket["results"] as? [[String: Any]] ?? [] {
                    guard let amount = result["amount"] as? [String: Any],
                          let value = number(amount["value"]) else { continue }
                    let currency = (amount["currency"] as? String ?? "usd").uppercased()
                    costsByCurrency[currency, default: 0] += value
                }
            }
            let currency = costsByCurrency.keys.sorted().first ?? "USD"
            let total = costsByCurrency[currency] ?? 0
            let symbol = self.symbol(for: currency)
            await setExternalSummary(
                title: symbol + String(format: "%.2f", total),
                rows: [
                    ("最近 30 天成本", symbol + String(format: "%.2f", total)),
                    ("统计天数", "\(buckets.count) 天"),
                    ("接口口径", "组织 Costs API")
                ]
            )
        } catch { await setExternalError(.openai, error) }
    }

    private func fetchOpenRouter() async {
        guard let key = await credential(for: .openrouter),
              let url = URL(string: "https://openrouter.ai/api/v1/credits") else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer " + key, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15
        do {
            let (data, _) = try await performRequest(request)
            guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let values = root["data"] as? [String: Any],
                  let total = number(values["total_credits"]),
                  let usage = number(values["total_usage"]) else {
                throw queryError("OpenRouter 返回数据缺少额度信息")
            }
            let remaining = max(0, total - usage)
            await setExternalSummary(
                title: "$" + String(format: "%.2f", remaining),
                rows: [
                    ("剩余额度", "$" + String(format: "%.2f", remaining)),
                    ("已购额度", "$" + String(format: "%.2f", total)),
                    ("累计用量", "$" + String(format: "%.2f", usage))
                ],
                fractionRemaining: total > 0 ? remaining / total : nil
            )
        } catch { await setExternalError(.openrouter, error) }
    }

    private func fetchSiliconFlow() async {
        guard let key = await credential(for: .siliconflow),
              let url = URL(string: "https://api.siliconflow.cn/v1/user/info") else { return }
        var request = URLRequest(url: url)
        request.setValue("Bearer " + key, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15
        do {
            let (data, _) = try await performRequest(request)
            guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let values = root["data"] as? [String: Any],
                  let total = number(values["totalBalance"] ?? values["total_balance"] ?? values["balance"]) else {
                throw queryError("硅基流动返回数据缺少账户余额")
            }
            let gift = number(values["balance"]) ?? 0
            let charged = number(values["chargeBalance"] ?? values["charge_balance"]) ?? max(0, total - gift)
            await setExternalSummary(
                title: "¥" + String(format: "%.2f", total),
                rows: [
                    ("总余额", "¥" + String(format: "%.2f", total)),
                    ("充值余额", "¥" + String(format: "%.2f", charged)),
                    ("赠送余额", "¥" + String(format: "%.2f", gift))
                ]
            )
        } catch { await setExternalError(.siliconflow, error) }
    }

    private func performRequest(
        _ request: URLRequest,
        maximumAttempts: Int = 2
    ) async throws -> (Data, HTTPURLResponse) {
        var lastError: Error?
        let attempts = max(1, maximumAttempts)

        for attempt in 0..<attempts {
            do {
                try Task.checkCancellation()
                let (data, response) = try await configuredURLSession().data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    throw queryError("服务器返回了无效响应")
                }
                if (200..<300).contains(http.statusCode) { return (data, http) }

                if attempt + 1 < attempts, http.statusCode == 429 || (500..<600).contains(http.statusCode) {
                    try await Task.sleep(nanoseconds: UInt64(450_000_000 * (attempt + 1)))
                    continue
                }
                throw queryError(Self.httpErrorMessage(statusCode: http.statusCode, data: data))
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                lastError = error
                guard attempt + 1 < attempts, Self.isTransientNetworkError(error) else { throw error }
                try await Task.sleep(nanoseconds: UInt64(450_000_000 * (attempt + 1)))
            }
        }
        throw lastError ?? queryError("请求失败")
    }

    static func isTransientNetworkError(_ error: Error) -> Bool {
        guard let error = error as? URLError else { return false }
        return [
            .timedOut, .cannotFindHost, .cannotConnectToHost, .networkConnectionLost,
            .dnsLookupFailed, .notConnectedToInternet, .internationalRoamingOff,
            .callIsActive, .dataNotAllowed
        ].contains(error.code)
    }

    static func httpErrorMessage(statusCode: Int, data: Data) -> String {
        let detail = apiErrorDetail(from: data)
        let headline: String
        switch statusCode {
        case 401: headline = "凭证无效或已过期"
        case 403: headline = "凭证权限不足"
        case 404: headline = "额度接口不存在或已变更"
        case 429: headline = "请求过于频繁，请稍后重试"
        case 500..<600: headline = "服务暂时不可用"
        default: headline = "请求失败（HTTP \(statusCode)）"
        }
        guard let detail, !detail.isEmpty else { return headline }
        return headline + "：" + sanitizedErrorMessage(detail)
    }

    private static func apiErrorDetail(from data: Data) -> String? {
        guard !data.isEmpty,
              let object = try? JSONSerialization.jsonObject(with: data) else { return nil }
        if let root = object as? [String: Any] {
            if let error = root["error"] as? [String: Any] {
                return error["message"] as? String ?? error["msg"] as? String
            }
            return root["message"] as? String ?? root["msg"] as? String
        }
        return nil
    }

    static func sanitizedErrorMessage(_ rawMessage: String) -> String {
        var message = rawMessage
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
        let patterns = [
            "(?i)(bearer\\s+)[^\\s,;\\\"]+",
            "(?i)\\b(sk(?:-[a-z0-9]+)?-[a-z0-9_-]{8,})\\b",
            "(?i)(api[_ -]?key|authorization)([\\\"']?\\s*[:=]\\s*[\\\"']?)[^\\s,;\\\"'}]+"
        ]
        for (index, pattern) in patterns.enumerated() {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(message.startIndex..<message.endIndex, in: message)
            let replacement = index == 0 ? "$1[已隐藏]" : (index == 1 ? "[密钥已隐藏]" : "$1$2[已隐藏]")
            message = regex.stringByReplacingMatches(in: message, range: range, withTemplate: replacement)
        }
        message = message.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
        return String(message.prefix(240))
    }

    private func queryError(_ message: String) -> Error {
        NSError(domain: "APIQuotaDashboard.Query", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }

    private func number(_ value: Any?) -> Double? {
        if let value = value as? NSNumber { return value.doubleValue }
        if let value = value as? String { return Double(value) }
        return nil
    }

    private func flattenedScalars(_ value: Any, path: String = "") -> [(String, String)] {
        if let dictionary = value as? [String: Any] {
            return dictionary.sorted { $0.key < $1.key }.flatMap {
                flattenedScalars($0.value, path: path.isEmpty ? $0.key : path + "." + $0.key)
            }
        }
        if let array = value as? [Any] {
            return array.enumerated().flatMap { flattenedScalars($0.element, path: path + "[\($0.offset)]") }
        }
        if value is NSNull { return [] }
        return [(path, String(describing: value))]
    }

    private func flattenedNumbers(_ value: Any, path: String = "") -> [(String, Double)] {
        if let dictionary = value as? [String: Any] {
            return dictionary.flatMap {
                flattenedNumbers($0.value, path: path.isEmpty ? $0.key : path + "." + $0.key)
            }
        }
        if let array = value as? [Any] {
            return array.enumerated().flatMap { flattenedNumbers($0.element, path: path + "[\($0.offset)]") }
        }
        return number(value).map { [(path, $0)] } ?? []
    }

    private func readableJSONPath(_ path: String) -> String {
        path.split(separator: ".").last.map(String.init) ?? path
    }

    private func setExternalSummary(
        title: String,
        rows: [(String, String)],
        fractionRemaining: Double? = nil
    ) async {
        await setState {
            self.externalSummary = ExternalQuotaSummary(
                menuBarTitle: title,
                rows: rows,
                fractionRemaining: fractionRemaining
            )
            self.errorMessage = nil
            self.lastUpdated = Date()
        }
    }

    private func setExternalError(_ provider: Provider, _ error: Error) async {
        let safeMessage = Self.sanitizedErrorMessage(error.localizedDescription)
        await setState {
            self.externalSummary = nil
            self.errorMessage = safeMessage
        }
        log("\(provider.displayName) error: " + safeMessage)
    }

    private func setState(_ body: @escaping () -> Void) async {
        let requestedProvider = FetchContext.provider
        let generation = FetchContext.generation
        await MainActor.run {
            if let requestedProvider, let generation {
                guard Self.shouldApplyFetchResult(
                    requestedProvider: requestedProvider,
                    currentProvider: self.provider,
                    generation: generation,
                    currentGeneration: self.refreshGeneration
                ) else { return }
            }
            body()
            self.onUpdate?()
        }
    }

    private func log(_ msg: String) {
        try? FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)
        let f = configDir.appendingPathComponent("app.log")
        rotateLogIfNeeded(at: f)
        let line = "[" + ISO8601DateFormatter().string(from: Date()) + "] "
            + Self.sanitizedErrorMessage(msg) + "\n"
        if let h = try? FileHandle(forWritingTo: f) {
            h.seekToEndOfFile()
            if let d = line.data(using: .utf8) { h.write(d) }
            try? h.close()
        } else {
            try? line.write(to: f, atomically: true, encoding: .utf8)
        }
    }

    private func rotateLogIfNeeded(at url: URL) {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? NSNumber,
              size.uint64Value >= Self.maximumLogSize else { return }
        let archived = url.deletingLastPathComponent().appendingPathComponent("app.log.1")
        try? FileManager.default.removeItem(at: archived)
        try? FileManager.default.moveItem(at: url, to: archived)
    }
}

// MARK: - App delegate

private final class StatusItemTitleView: NSView {
    private struct RenderedLine {
        let text: String
        let font: NSFont
        let color: NSColor
        let horizontalOffset: CGFloat

        var attributes: [NSAttributedString.Key: Any] {
            [.font: font, .foregroundColor: color]
        }

        var size: NSSize {
            (text as NSString).size(withAttributes: attributes)
        }
    }

    private var renderedLines: [RenderedLine] = []

    var contentWidth: CGFloat {
        renderedLines.map { ceil($0.size.width) }.max() ?? 0
    }

    func update(lines: [MenuBarDisplayLine], fallbackColor: NSColor, isStale: Bool) {
        let isDoubleLine = lines.count == 2
        renderedLines = lines.enumerated().map { index, line in
            let font: NSFont
            if isDoubleLine {
                font = index == 0
                    ? .systemFont(ofSize: 10.5, weight: .medium)
                    : .systemFont(ofSize: 12, weight: .semibold)
            } else {
                font = .menuBarFont(ofSize: 0)
            }
            let color: NSColor
            if isStale {
                color = .systemOrange
            } else if let percentage = line.percentage {
                color = BalanceService.tenStepColor(value: percentage, max: 100)
            } else {
                color = fallbackColor
            }
            return RenderedLine(text: line.text, font: font, color: color, horizontalOffset: line.horizontalOffset)
        }
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard !renderedLines.isEmpty else { return }

        if renderedLines.count == 1, let line = renderedLines.first {
            let size = line.size
            let origin = NSPoint(
                x: floor((bounds.width - size.width) / 2),
                y: floor((bounds.height - size.height) / 2)
            )
            (line.text as NSString).draw(at: origin, withAttributes: line.attributes)
            return
        }

        let top = renderedLines[0]
        let bottom = renderedLines[1]
        let topSize = top.size
        let bottomSize = bottom.size
        let overlap: CGFloat = 2.5
        let totalHeight = topSize.height + bottomSize.height - overlap
        let bottomY = floor((bounds.height - totalHeight) / 2) - 1.5
        let topY = bottomY + bottomSize.height - overlap

        (bottom.text as NSString).draw(
            at: NSPoint(x: floor((bounds.width - bottomSize.width) / 2) - 0.5 + bottom.horizontalOffset, y: bottomY),
            withAttributes: bottom.attributes
        )
        (top.text as NSString).draw(
            at: NSPoint(x: floor((bounds.width - topSize.width) / 2), y: topY),
            withAttributes: top.attributes
        )
    }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private static let statusItemHorizontalPadding: CGFloat = 2
    private static let minimumStatusItemWidth: CGFloat = 18
    private static let maximumStatusItemWidth: CGFloat = 96
    static let initialStatusItemWidth: CGFloat = 52
    static let statusItemAutosaveName = "APIQuotaDashboardQuotaV3"
    static let statusItemBaselineOffset: CGFloat = 0
    private var statusItem: NSStatusItem?
    private var statusTitleView: StatusItemTitleView?
    private var menu: NSMenu?
    private var service: BalanceService?
    private var appearanceTimer: Timer?
    private var lastDarkAppearance: Bool?
    private var settingsWindowController: SettingsWindowController?

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    private static let dateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM-dd HH:mm"
        return f
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        installStatusItem()
        if CommandLine.arguments.contains("--show-settings") {
            DispatchQueue.main.async { [weak self] in
                self?.showSettingsWindow()
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        appearanceTimer?.invalidate()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    func setup() {
        guard service == nil else { return }
        let service = BalanceService()
        self.service = service

        let menu = NSMenu()
        menu.delegate = self
        self.menu = menu

        service.onUpdate = { [weak self] in
            guard let self else { return }
            self.updateStatusItem()
            self.settingsWindowController?.syncMenuBarQuotaDisplayMode()
            self.updateApplicationIconForCurrentAppearance(force: true)
        }
        updateApplicationIconForCurrentAppearance(force: true)
        appearanceTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.updateApplicationIconForCurrentAppearance()
        }
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(workspaceDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    @objc private func workspaceDidWake() {
        service?.refreshIfStale()
    }

    private func installStatusItem() {
        guard statusItem == nil, let menu else { return }

        // Create the item only after AppKit finishes launching, when macOS has
        // established the system menu extras. Reserve a stable slot first, then
        // shrink it after the status bar has placed the new window.
        let item = NSStatusBar.system.statusItem(withLength: Self.initialStatusItemWidth)
        statusItem = item
        item.isVisible = true
        item.button?.alignment = .center
        item.button?.cell?.wraps = true
        item.button?.cell?.usesSingleLineMode = false
        item.button?.cell?.lineBreakMode = .byClipping
        if let button = item.button {
            let titleView = StatusItemTitleView(frame: button.bounds)
            titleView.autoresizingMask = [.width, .height]
            button.addSubview(titleView)
            statusTitleView = titleView
        }
        item.menu = menu
        updateStatusItem(adjustLength: false)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self else { return }
            self.statusItem?.isVisible = true
            self.updateStatusItem()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            // Binding autosaveName during creation makes macOS 26 place the
            // item beneath the clock. Bind it only after the initial placement
            // so Command-dragged positions can still be restored and saved.
            self?.statusItem?.autosaveName = Self.statusItemAutosaveName
            self?.statusItem?.isVisible = true
            self?.logStatusItemState()
        }
    }

    private func logStatusItemState() {
        guard let item = statusItem, let button = item.button else { return }
        let frame = button.window?.frame.debugDescription ?? "nil"
        let line = "[" + ISO8601DateFormatter().string(from: Date()) + "] StatusItem visible=\(item.isVisible) length=\(item.length) hidden=\(button.isHidden) title=\(button.title) window=\(frame)\n"
        let logURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".api-quota-dashboard", isDirectory: true)
            .appendingPathComponent("app.log")
        if let handle = try? FileHandle(forWritingTo: logURL) {
            handle.seekToEndOfFile()
            if let data = line.data(using: .utf8) { handle.write(data) }
            try? handle.close()
        }
    }

    private func updateApplicationIconForCurrentAppearance(force: Bool = false) {
        let match = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua])
        let isDark = match == .darkAqua
        guard force || lastDarkAppearance != isDark else { return }
        lastDarkAppearance = isDark

        let appearance = service?.iconAppearance ?? .system
        let resourceName: String
        switch appearance {
        case .white: resourceName = "APIQuotaDashboard"
        case .black: resourceName = "APIQuotaDashboardDark"
        case .system:
            // Preserve the adaptive Icon Composer asset so macOS can render
            // its light/dark material variants instead of replacing it with a
            // legacy static image after every quota refresh.
            if let adaptiveIcon = NSImage(named: NSImage.applicationIconName) {
                NSApp.applicationIconImage = adaptiveIcon
            }
            return
        case .transparent:
            if let url = Bundle.main.url(forResource: "APIQuotaDashboard", withExtension: "icns"),
               let image = NSImage(contentsOf: url),
               let transparent = transparentIcon(from: image) {
                NSApp.applicationIconImage = transparent
            }
            return
        }
        if let url = Bundle.main.url(forResource: resourceName, withExtension: "icns"),
           let image = NSImage(contentsOf: url) {
            NSApp.applicationIconImage = image
        }
    }

    private func transparentIcon(from source: NSImage) -> NSImage? {
        guard let tiff = source.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff) else { return nil }
        let width = bitmap.pixelsWide
        let height = bitmap.pixelsHigh
        for y in 0..<height {
            for x in 0..<width {
                guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB) else { continue }
                let saturation = max(color.redComponent, color.greenComponent, color.blueComponent)
                    - min(color.redComponent, color.greenComponent, color.blueComponent)
                let alpha = saturation > 0.08 ? color.alphaComponent * 0.78 : 0
                bitmap.setColor(color.withAlphaComponent(alpha), atX: x, y: y)
            }
        }
        let result = NSImage(size: source.size)
        result.addRepresentation(bitmap)
        return result
    }

    func menuWillOpen(_ menu: NSMenu) {
        updateStatusItem()
    }

    @objc private func refreshTapped() { service?.refresh() }
    @objc private func quitTapped() { NSApp.terminate(nil) }
    @objc private func switchToDeepSeek() { service?.setProvider(.deepseek) }
    @objc private func switchToVolcengine() { service?.setProvider(.volcengine) }
    @objc private func switchToCodex() { service?.setProvider(.codex) }
    @objc private func switchProviderTapped(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let provider = Provider(rawValue: rawValue) else { return }
        service?.setProvider(provider)
    }
    @objc private func openProviderDashboardTapped() {
        guard let url = service?.provider.dashboardURL else { return }
        NSWorkspace.shared.open(url)
    }
    @objc private func refreshIntervalTapped(_ sender: NSMenuItem) {
        guard let seconds = (sender.representedObject as? NSNumber)?.doubleValue else { return }
        service?.setRefreshInterval(seconds)
    }
    @objc private func quotaDisplayModeTapped(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let mode = MenuBarQuotaDisplayMode(rawValue: rawValue) else { return }
        service?.setMenuBarQuotaDisplayMode(mode)
    }

    private func refreshIntervalTitle(_ seconds: TimeInterval) -> String {
        switch Int(seconds) {
        case 15: return "15 秒"
        case 30: return "30 秒"
        case 60: return "1 分钟"
        case 120: return "2 分钟"
        case 300: return "5 分钟"
        default: return "\(Int(seconds)) 秒"
        }
    }

    @objc private func customRefreshTapped() {
        guard let service else { return }
        let alert = NSAlert()
        alert.messageText = "自定义刷新时间"
        alert.informativeText = "请输入 5–86400 秒之间的时间。"
        alert.addButton(withTitle: "应用")
        alert.addButton(withTitle: "取消")
        let field = NSTextField(string: String(Int(service.refreshIntervalSeconds)))
        field.frame = NSRect(x: 0, y: 0, width: 220, height: 24)
        alert.accessoryView = field
        guard alert.runModal() == .alertFirstButtonReturn,
              let seconds = Double(field.stringValue),
              seconds >= 5, seconds <= 86_400 else { return }
        service.setRefreshInterval(seconds)
    }

    @objc private func settingsTapped() {
        guard let service else { return }
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(service: service)
        }
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showSettingsWindow() {
        settingsTapped()
    }

    private func updateStatusItem(adjustLength: Bool = true) {
        guard let item = statusItem, let button = item.button, let menu = menu, let service = service else { return }

        // --- Menu bar title ---
        let lines = service.displayedMenuBarLineModels
        statusTitleView?.update(
            lines: lines,
            fallbackColor: service.menuBarColor,
            isStale: service.isDataStale
        )
        button.attributedTitle = NSAttributedString(string: "")
        button.setAccessibilityLabel("API 额度看板，\(service.provider.displayName)，\(service.menuBarTitle)")
        button.toolTip = service.provider.displayName + " · " + service.freshnessDescription
        if adjustLength {
            item.length = Self.statusItemLength(contentWidth: statusTitleView?.contentWidth ?? 0)
        }

        // --- Menu ---
        menu.removeAllItems()

        // Header
        let header = NSMenuItem()
        header.attributedTitle = NSAttributedString(
            string: service.provider.displayName,
            attributes: [.font: NSFont.systemFont(ofSize: 14, weight: .bold), .foregroundColor: NSColor.labelColor]
        )
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        // Content
        switch service.provider {
        case .deepseek: buildDeepSeekMenu(menu, service: service)
        case .volcengine: buildVolcengineMenu(menu, service: service)
        case .codex: buildCodexMenu(menu, service: service)
        case .doubao: buildDoubaoMenu(menu, service: service)
        case .claude, .gemini, .kimi, .qwen, .minimax, .openai, .openrouter, .siliconflow, .zhipu:
            buildExternalProviderMenu(menu, service: service)
        case .wenxin, .hunyuan:
            buildLocalProviderMenu(menu, service: service)
        }

        menu.addItem(.separator())

        // Provider switch submenu
        let providerItem = NSMenuItem(title: "切换提供方", action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        submenu.title = "切换提供方"

        for (index, provider) in service.enabledProviders.enumerated() {
            let providerOption = NSMenuItem(
                title: provider.displayName,
                action: #selector(switchProviderTapped(_:)),
                keyEquivalent: index < 9 ? String(index + 1) : ""
            )
            providerOption.target = self
            if index < 9 { providerOption.keyEquivalentModifierMask = [.command] }
            providerOption.representedObject = provider.rawValue
            if service.provider == provider { providerOption.state = .on }
            submenu.addItem(providerOption)
        }

        providerItem.submenu = submenu
        menu.addItem(providerItem)

        let intervalItem = NSMenuItem(title: "自动刷新时间", action: nil, keyEquivalent: "")
        let intervalMenu = NSMenu()
        intervalMenu.title = "自动刷新时间"
        for seconds in BalanceService.allowedRefreshIntervals {
            let option = NSMenuItem(
                title: refreshIntervalTitle(seconds),
                action: #selector(refreshIntervalTapped(_:)),
                keyEquivalent: ""
            )
            option.target = self
            option.representedObject = NSNumber(value: seconds)
            if abs(service.refreshIntervalSeconds - seconds) < 0.1 { option.state = .on }
            intervalMenu.addItem(option)
        }
        intervalMenu.addItem(.separator())
        let custom = NSMenuItem(title: "自定义…", action: #selector(customRefreshTapped), keyEquivalent: "")
        custom.target = self
        if !BalanceService.allowedRefreshIntervals.contains(service.refreshIntervalSeconds) {
            custom.title = "自定义：\(Int(service.refreshIntervalSeconds)) 秒"
            custom.state = .on
        }
        intervalMenu.addItem(custom)
        intervalItem.submenu = intervalMenu
        menu.addItem(intervalItem)

        if service.hasFiveHourQuota {
            let quotaDisplayItem = NSMenuItem(title: "5 小时显示方式", action: nil, keyEquivalent: "")
            let quotaDisplayMenu = NSMenu()
            quotaDisplayMenu.title = "5 小时显示方式"
            for mode in MenuBarQuotaDisplayMode.allCases {
                let option = NSMenuItem(
                    title: mode.displayName,
                    action: #selector(quotaDisplayModeTapped(_:)),
                    keyEquivalent: ""
                )
                option.target = self
                option.representedObject = mode.rawValue
                if service.menuBarQuotaDisplayMode == mode { option.state = .on }
                quotaDisplayMenu.addItem(option)
            }
            quotaDisplayItem.submenu = quotaDisplayMenu
            menu.addItem(quotaDisplayItem)
        }

        menu.addItem(.separator())

        let refresh = NSMenuItem(
            title: service.isRefreshing ? "正在刷新…" : "立即刷新",
            action: #selector(refreshTapped),
            keyEquivalent: "r"
        )
        refresh.target = self
        refresh.isEnabled = !service.isRefreshing
        menu.addItem(refresh)

        let openDashboard = NSMenuItem(title: "打开官方控制台", action: #selector(openProviderDashboardTapped), keyEquivalent: "")
        openDashboard.target = self
        openDashboard.isEnabled = service.provider.dashboardURL != nil
        menu.addItem(openDashboard)

        let settings = NSMenuItem(title: "设置…", action: #selector(settingsTapped), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)

        let quit = NSMenuItem(title: "退出", action: #selector(quitTapped), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
    }

    static func statusItemLength(contentWidth: CGFloat) -> CGFloat {
        min(
            maximumStatusItemWidth,
            max(minimumStatusItemWidth, ceil(contentWidth) + statusItemHorizontalPadding)
        )
    }

    private func buildDeepSeekMenu(_ menu: NSMenu, service: BalanceService) {
        if let b = service.dsBalance {
            let sym = service.symbol(for: b.currency)
            menu.addItem(row(label: "总余额", value: sym + b.totalBalance, bold: true))
            menu.addItem(row(label: "充值余额", value: sym + b.toppedUpBalance))
            menu.addItem(row(label: "赠送余额", value: sym + b.grantedBalance))

            if let max = service.dsScaleMax, max > 0 {
                menu.addItem(row(label: "十档基准", value: sym + String(format: "%.2f", max)))
            }

            menu.addItem(timestampRow(service.freshnessDescription))
        } else if let e = service.errorMessage {
            menu.addItem(errorRow("查询失败", detail: e))
        } else {
            menu.addItem(loadingRow())
        }
    }

    private func buildVolcengineMenu(_ menu: NSMenu, service: BalanceService) {
        var displayed = false

        if let plan = service.volcPlanSummary, !plan.items.isEmpty {
            displayed = true
            let planHeader = NSMenuItem()
            planHeader.attributedTitle = NSAttributedString(
                string: "订阅额度",
                attributes: [.font: NSFont.systemFont(ofSize: 12, weight: .semibold), .foregroundColor: NSColor.secondaryLabelColor]
            )
            planHeader.isEnabled = false
            menu.addItem(planHeader)

            for item in plan.items {
                let planName = [item.product, item.tier].compactMap { $0 }.joined(separator: " · ")
                menu.addItem(row(label: "套餐", value: planName, color: .labelColor, bold: true))
                for period in item.periods {
                    let label: String
                    switch period.label {
                    case "5h": label = "5 小时剩余"
                    case "weekly": label = "每周剩余"
                    case "monthly": label = "每月剩余"
                    case "session": label = "会话剩余"
                    default: label = period.label + " 剩余"
                    }
                    if let remaining = period.remainingPercent {
                        menu.addItem(row(
                            label: label,
                            value: String(format: "%.0f%%", remaining),
                            bold: true
                        ))
                    }
                }
            }
        }

        if let s = service.volcSummary {
            if displayed { menu.addItem(.separator()) }
            displayed = true
            let freeHeader = NSMenuItem()
            freeHeader.attributedTitle = NSAttributedString(
                string: "免费额度",
                attributes: [.font: NSFont.systemFont(ofSize: 12, weight: .semibold), .foregroundColor: NSColor.secondaryLabelColor]
            )
            freeHeader.isEnabled = false
            menu.addItem(freeHeader)

            let totalStr = service.formatTokens(s.totalRemaining) + " tokens"
            menu.addItem(row(label: "剩余总额度", value: totalStr, bold: true))
            menu.addItem(row(label: "有额度模型", value: "\(s.modelsWithQuota) / \(s.totalModels) 个"))

            if s.totalQuota > 0 {
                let pct = Double(s.totalRemaining) / Double(s.totalQuota) * 100
                menu.addItem(row(label: "剩余比例", value: String(format: "%.1f%%", pct)))
            }

            menu.addItem(.separator())

            let topHeader = NSMenuItem()
            topHeader.attributedTitle = NSAttributedString(
                string: "模型额度明细（Top \(s.topModels.count)）",
                attributes: [.font: NSFont.systemFont(ofSize: 12, weight: .semibold), .foregroundColor: NSColor.secondaryLabelColor]
            )
            topHeader.isEnabled = false
            menu.addItem(topHeader)

            for m in s.topModels {
                let rem = service.formatTokens(m.remaining)
                let color: NSColor = m.remaining > 0 ? .labelColor : .tertiaryLabelColor
                menu.addItem(row(label: m.name, value: rem, color: color))
            }

        }

        if displayed {
            menu.addItem(timestampRow(service.freshnessDescription))
        } else if !displayed, let e = service.errorMessage {
            menu.addItem(errorRow("查询失败", detail: e))
        } else if !displayed {
            menu.addItem(loadingRow())
        }
    }

    private func buildLocalProviderMenu(_ menu: NSMenu, service: BalanceService) {
        if let path = service.localProviderPath {
            menu.addItem(row(label: "本机状态", value: "已安装", color: .systemGreen, bold: true))
            menu.addItem(row(label: "位置", value: path))
            menu.addItem(timestampRow(service.provider.queryAvailabilityDescription))
        } else {
            menu.addItem(errorRow("未检测到软件", detail: "可在设置中重新扫描"))
        }
    }

    private func buildDoubaoMenu(_ menu: NSMenu, service: BalanceService) {
        if let summary = service.doubaoSummary {
            for (index, entry) in summary.rows.enumerated() {
                menu.addItem(row(label: entry.0, value: entry.1, bold: index == 0))
            }
            menu.addItem(timestampRow(service.freshnessDescription))
        } else if let error = service.errorMessage {
            menu.addItem(errorRow("尚未查询", detail: error))
            menu.addItem(timestampRow("确认豆包客户端仍保持登录后，点击刷新"))
        } else {
            menu.addItem(loadingRow())
        }
    }

    private func buildExternalProviderMenu(_ menu: NSMenu, service: BalanceService) {
        if let summary = service.externalSummary {
            for (index, entry) in summary.rows.enumerated() {
                menu.addItem(row(label: entry.0, value: entry.1, bold: index == 0))
            }
            menu.addItem(timestampRow(service.freshnessDescription))
        } else if let error = service.errorMessage {
            menu.addItem(errorRow("尚未查询", detail: error))
        } else {
            menu.addItem(loadingRow())
        }
    }

    private func buildCodexMenu(_ menu: NSMenu, service: BalanceService) {
        if let s = service.codexSummary {
            // Plan
            menu.addItem(row(label: "订阅计划", value: s.planType.uppercased()))

            // Weekly
            if let pct = s.weeklyRemaining {
                menu.addItem(row(label: "每周剩余", value: String(format: "%.0f%%", pct), bold: true))
            }
            if let reset = s.weeklyResetAt {
                menu.addItem(row(label: "每周重置", value: Self.dateTimeFormatter.string(from: reset)))
            }

            // 5h
            if let pct = s.fiveHourRemaining {
                menu.addItem(row(label: "5小时剩余", value: String(format: "%.0f%%", pct), bold: true))
            }
            if let reset = s.fiveHourResetAt {
                menu.addItem(row(label: "5h重置", value: Self.dateTimeFormatter.string(from: reset)))
            }

            // Limit reached warning
            if s.limitReached {
                let warn = NSMenuItem()
                warn.attributedTitle = NSAttributedString(
                    string: "⚠ 已达限额",
                    attributes: [.foregroundColor: NSColor.systemRed, .font: NSFont.systemFont(ofSize: 12, weight: .semibold)]
                )
                warn.isEnabled = false
                menu.addItem(warn)
            }

            menu.addItem(timestampRow(service.freshnessDescription))
        } else if let e = service.errorMessage {
            menu.addItem(errorRow("查询失败", detail: e))
        } else {
            menu.addItem(loadingRow())
        }
    }

    private func row(label: String, value: String, color: NSColor = .labelColor, bold: Bool = false) -> NSMenuItem {
        let full = label + "    " + value
        let a = NSMutableAttributedString(string: full)
        a.addAttribute(.font, value: NSFont.systemFont(ofSize: 13), range: NSRange(location: 0, length: a.length))
        a.addAttribute(.foregroundColor, value: NSColor.labelColor, range: NSRange(location: 0, length: a.length))
        if let r = full.range(of: value) {
            let nsr = NSRange(r, in: full)
            a.addAttribute(.foregroundColor, value: color, range: nsr)
            if bold {
                a.addAttribute(.font, value: NSFont.systemFont(ofSize: 13, weight: .semibold), range: nsr)
            }
        }
        let item = NSMenuItem()
        item.attributedTitle = a
        item.isEnabled = false
        return item
    }

    private func timestampRow(_ text: String) -> NSMenuItem {
        let t = NSMenuItem()
        t.attributedTitle = NSAttributedString(
            string: text,
            attributes: [.foregroundColor: NSColor.secondaryLabelColor, .font: NSFont.systemFont(ofSize: 11)]
        )
        t.isEnabled = false
        return t
    }

    private func loadingRow() -> NSMenuItem {
        let loading = NSMenuItem(title: "正在加载…", action: nil, keyEquivalent: "")
        loading.isEnabled = false
        return loading
    }

    private func errorRow(_ title: String, detail: String) -> NSMenuItem {
        let container = NSMenuItem()
        container.isEnabled = false
        let full = title + "\n" + detail
        let a = NSMutableAttributedString(string: full)
        a.addAttribute(.font, value: NSFont.systemFont(ofSize: 13, weight: .semibold), range: NSRange(location: 0, length: title.count))
        a.addAttribute(.foregroundColor, value: NSColor.systemRed, range: NSRange(location: 0, length: title.count))
        if detail.count > 0 {
            let detailRange = NSRange(location: title.count + 1, length: detail.count)
            a.addAttribute(.font, value: NSFont.systemFont(ofSize: 11), range: detailRange)
            a.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: detailRange)
        }
        container.attributedTitle = a
        return container
    }
}

// MARK: - Entry point

@main
final class Main {
    private static var appDelegate: AppDelegate?

    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)
        let delegate = AppDelegate()
        appDelegate = delegate
        app.delegate = delegate
        // Initialize data services before entering AppKit's run loop. The
        // status item itself is installed from applicationDidFinishLaunching,
        // after macOS has placed the system menu extras.
        delegate.setup()
        app.run()
    }
}

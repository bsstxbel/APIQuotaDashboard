import CommonCrypto
import CryptoKit
import Foundation
import Security

struct ZhipuQuotaPackage: Equatable {
    let name: String
    let type: String
    let status: String
    let suitableScene: String
    let total: Double
    let available: Double
    let consumeType: String
    let tokenPurpose: String
    let expirationTime: String?

    var isEffective: Bool {
        status.isEmpty || status.uppercased() == "EFFECTIVE"
    }

    var unit: String {
        switch consumeType.uppercased() {
        case "TOKENS": return "tokens"
        case "TIMES": return "次"
        default:
            return tokenPurpose.uppercased() == "PRIVATE_INSTANCE" ? "算力单元" : "额度"
        }
    }
}

struct ZhipuFinanceBalance: Equatable {
    let availableBalance: Double
    let giftBalance: Double
}

struct ZhipuQuotaSummary: Equatable {
    let packages: [ZhipuQuotaPackage]
    let financeBalance: ZhipuFinanceBalance?

    var effectivePackages: [ZhipuQuotaPackage] {
        packages.filter(\.isEffective)
    }

    var tokenPackages: [ZhipuQuotaPackage] {
        effectivePackages.filter { $0.consumeType.uppercased() == "TOKENS" }
    }

    var tokenTotal: Double { tokenPackages.reduce(0) { $0 + $1.total } }
    var tokenAvailable: Double { tokenPackages.reduce(0) { $0 + $1.available } }

    var fractionRemaining: Double? {
        guard tokenTotal > 0 else { return nil }
        return max(0, min(1, tokenAvailable / tokenTotal))
    }

    var menuBarTitle: String {
        if tokenTotal > 0 { return Self.compactNumber(tokenAvailable) }
        let times = effectivePackages
            .filter { $0.consumeType.uppercased() == "TIMES" }
            .reduce(0) { $0 + $1.available }
        return times > 0 ? Self.compactNumber(times) + "次" : "0包"
    }

    var rows: [(String, String)] {
        var result: [(String, String)] = []
        if tokenTotal > 0 {
            result.append((
                "Token 包合计",
                "\(Self.compactNumber(tokenAvailable)) / \(Self.compactNumber(tokenTotal)) tokens"
            ))
        }

        for package in effectivePackages.prefix(8) {
            result.append((
                Self.shortPackageName(package.name),
                "\(Self.compactNumber(package.available)) / \(Self.compactNumber(package.total)) \(package.unit)"
            ))
        }

        if let expiry = earliestExpirationText {
            result.append(("最早到期", expiry))
        }
        if let financeBalance {
            result.append(("账户可用余额", Self.currencyText(financeBalance.availableBalance)))
            if financeBalance.giftBalance > 0 {
                result.append(("赠送金额", Self.currencyText(financeBalance.giftBalance)))
            }
        }
        result.append(("免费模型", "GLM-4.7-Flash（平台标为免费）"))
        return result
    }

    private var earliestExpirationText: String? {
        let expirations = effectivePackages.compactMap { package -> (Date, String)? in
            guard let raw = package.expirationTime,
                  let date = Self.parseDate(raw) else { return nil }
            return (date, raw)
        }
        guard let earliest = expirations.min(by: { $0.0 < $1.0 }) else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: earliest.0)
    }

    private static func parseDate(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
        for format in ["yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd'T'HH:mm:ss.SSSZ", "yyyy-MM-dd'T'HH:mm:ssZ"] {
            formatter.dateFormat = format
            if let date = formatter.date(from: value) { return date }
        }
        return nil
    }

    private static func shortPackageName(_ name: String) -> String {
        name
            .replacingOccurrences(of: "【新用户专享】", with: "")
            .replacingOccurrences(of: "资源包", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func compactNumber(_ value: Double) -> String {
        let magnitude: (Double, String)
        if value >= 100_000_000 {
            magnitude = (100_000_000, "亿")
        } else if value >= 10_000 {
            magnitude = (10_000, "万")
        } else {
            magnitude = (1, "")
        }
        let scaled = value / magnitude.0
        let number = scaled.rounded() == scaled
            ? String(Int(scaled))
            : String(format: "%.1f", scaled)
        return number + magnitude.1
    }

    private static func currencyText(_ value: Double) -> String {
        value.rounded() == value ? "¥\(Int(value))" : String(format: "¥%.2f", value)
    }
}

enum ZhipuQuotaReadError: LocalizedError {
    case chromeUnavailable
    case sessionUnavailable
    case keychainAccessDenied
    case cookieReadFailed
    case sessionExpired
    case requestFailed
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .chromeUnavailable:
            return "未检测到 Google Chrome"
        case .sessionUnavailable:
            return "未找到智谱登录会话；请先在 Chrome 登录 open.bigmodel.cn"
        case .keychainAccessDenied:
            return "无法读取 Chrome 登录会话；请允许 API 额度看板访问 Chrome Safe Storage 后重试"
        case .cookieReadFailed:
            return "无法读取本机 Chrome 中的智谱登录会话"
        case .sessionExpired:
            return "智谱登录会话已失效；请在 Chrome 重新登录后重试"
        case .requestFailed:
            return "智谱额度查询失败，请稍后重试"
        case .invalidResponse:
            return "智谱额度接口未返回可用的资源包数据"
        }
    }
}

/// Reads only the BigModel login cookie from local Chrome profiles. The value
/// is sent only to open.bigmodel.cn and is never written to app configuration.
enum ZhipuQuotaReader {
    private static let chromeRootRelativePath = "Library/Application Support/Google/Chrome"
    private static let safeStorageService = "Chrome Safe Storage"
    private static let safeStorageAccount = "Chrome"
    private static let cookieName = "bigmodel_token_production"
    private static let resourcePackageURL = URL(
        string: "https://open.bigmodel.cn/api/biz/tokenAccounts/list/my?pageNum=1&pageSize=100&filterEnabled=false"
    )!
    private static let financeURL = URL(
        string: "https://open.bigmodel.cn/api/biz/account/query-customer-account-report"
    )!
    private static let recordSeparator = "\u{1F}"
    private static let windowsEpochOffset: TimeInterval = 11_644_473_600

    static var hasChromeProfile: Bool {
        !cookieDatabaseURLs().isEmpty
    }

    static func fetch(session: URLSession = .shared) async throws -> ZhipuQuotaSummary {
        let tokens = try await Task.detached(priority: .userInitiated) {
            try sessionTokens()
        }.value

        var sawExpiredSession = false
        for token in tokens {
            do {
                let packageData = try await request(resourcePackageURL, token: token, session: session)
                var summary = try parseQuotaResponse(packageData)
                if let financeData = try? await request(financeURL, token: token, session: session),
                   let finance = try? parseFinanceResponse(financeData) {
                    summary = ZhipuQuotaSummary(packages: summary.packages, financeBalance: finance)
                }
                return summary
            } catch ZhipuQuotaReadError.sessionExpired {
                sawExpiredSession = true
            } catch ZhipuQuotaReadError.invalidResponse {
                continue
            }
        }
        if sawExpiredSession { throw ZhipuQuotaReadError.sessionExpired }
        throw ZhipuQuotaReadError.requestFailed
    }

    static func parseQuotaResponse(_ data: Data) throws -> ZhipuQuotaSummary {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              successCode(root["code"]) else {
            throw ZhipuQuotaReadError.invalidResponse
        }
        let dataBody = root["data"] as? [String: Any]
        let rawRows = (root["rows"] as? [[String: Any]])
            ?? (dataBody?["rows"] as? [[String: Any]])
            ?? []
        let packages = rawRows.compactMap { row -> ZhipuQuotaPackage? in
            guard let name = string(row["resourcePackageName"]) else { return nil }
            return ZhipuQuotaPackage(
                name: name,
                type: string(row["type"]) ?? "",
                status: string(row["status"]) ?? "",
                suitableScene: string(row["suitableScene"]) ?? "",
                total: number(row["tokenBalance"]) ?? 0,
                available: number(row["availableBalance"]) ?? number(row["realBalance"]) ?? 0,
                consumeType: string(row["consumeType"]) ?? "",
                tokenPurpose: string(row["tokenPurpose"]) ?? "",
                expirationTime: string(row["packageExpirationTime"])
            )
        }
        return ZhipuQuotaSummary(packages: packages, financeBalance: nil)
    }

    static func parseFinanceResponse(_ data: Data) throws -> ZhipuFinanceBalance {
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              successCode(root["code"]),
              let body = root["data"] as? [String: Any] else {
            throw ZhipuQuotaReadError.invalidResponse
        }
        return ZhipuFinanceBalance(
            availableBalance: number(body["availableBalance"]) ?? 0,
            giftBalance: number(body["giveAmount"]) ?? 0
        )
    }

    private static func request(_ url: URL, token: String, session: URLSession) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 20
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.setValue("\(cookieName)=\(token)", forHTTPHeaderField: "Cookie")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("zh-CN", forHTTPHeaderField: "Accept-Language")
        request.setValue("https://open.bigmodel.cn", forHTTPHeaderField: "Origin")
        request.setValue(
            "https://open.bigmodel.cn/finance-center/resource-package/package-mgmt?tab=my",
            forHTTPHeaderField: "Referer"
        )
        request.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/147 Safari/537.36",
            forHTTPHeaderField: "User-Agent"
        )

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ZhipuQuotaReadError.requestFailed
        }
        if http.statusCode == 401 || http.statusCode == 403 {
            throw ZhipuQuotaReadError.sessionExpired
        }
        guard (200 ... 299).contains(http.statusCode) else {
            throw ZhipuQuotaReadError.requestFailed
        }
        return data
    }

    private static func sessionTokens() throws -> [String] {
        let databases = cookieDatabaseURLs()
        guard !databases.isEmpty else { throw ZhipuQuotaReadError.chromeUnavailable }
        let password = try safeStoragePassword()
        let key = try deriveKey(from: password)
        var tokens: [String] = []
        var readAnyDatabase = false

        for database in databases {
            do {
                let records = try readCookieRecords(from: database)
                readAnyDatabase = true
                for record in records {
                    let value = !record.plainValue.isEmpty
                        ? record.plainValue
                        : (try decryptCookie(record, with: key) ?? "")
                    if !value.isEmpty, !tokens.contains(value) { tokens.append(value) }
                }
            } catch {
                continue
            }
        }
        guard readAnyDatabase else { throw ZhipuQuotaReadError.cookieReadFailed }
        guard !tokens.isEmpty else { throw ZhipuQuotaReadError.sessionUnavailable }
        return tokens
    }

    private static func cookieDatabaseURLs() -> [URL] {
        let root = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(chromeRootRelativePath, isDirectory: true)
        guard let profiles = try? FileManager.default.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return profiles
            .filter { $0.lastPathComponent == "Default" || $0.lastPathComponent.hasPrefix("Profile ") }
            .flatMap {
                [$0.appendingPathComponent("Network/Cookies"), $0.appendingPathComponent("Cookies")]
            }
            .filter { FileManager.default.fileExists(atPath: $0.path) }
    }

    private static func safeStoragePassword() throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: safeStorageService,
            kSecAttrAccount as String: safeStorageAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let password = item as? Data else {
            if status == errSecItemNotFound { throw ZhipuQuotaReadError.sessionUnavailable }
            throw ZhipuQuotaReadError.keychainAccessDenied
        }
        return password
    }

    private static func readCookieRecords(from databaseURL: URL) throws -> [ZhipuCookieRecord] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
        let now = Int64((Date().timeIntervalSince1970 + windowsEpochOffset) * 1_000_000)
        let sql = """
        SELECT host_key, path, name, value, hex(encrypted_value)
        FROM cookies
        WHERE host_key IN ('.bigmodel.cn', 'open.bigmodel.cn')
          AND name = '\(cookieName)'
          AND (expires_utc = 0 OR expires_utc > \(now))
        ORDER BY last_access_utc DESC;
        """
        process.arguments = ["-readonly", "-separator", recordSeparator, databaseURL.path, sql]
        let output = Pipe()
        process.standardOutput = output
        process.standardError = Pipe()
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw ZhipuQuotaReadError.cookieReadFailed }

        let text = String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return text.split(whereSeparator: \.isNewline).compactMap { line in
            let parts = line.components(separatedBy: recordSeparator)
            guard parts.count == 5 else { return nil }
            return ZhipuCookieRecord(
                host: parts[0],
                path: parts[1],
                name: parts[2],
                plainValue: parts[3],
                encryptedHex: parts[4]
            )
        }
    }

    private static func deriveKey(from password: Data) throws -> Data {
        let passwordBytes = [UInt8](password)
        let salt = Array("saltysalt".utf8)
        var key = [UInt8](repeating: 0, count: kCCKeySizeAES128)
        let keyCount = key.count
        let status = passwordBytes.withUnsafeBytes { passwordBuffer in
            salt.withUnsafeBytes { saltBuffer in
                key.withUnsafeMutableBytes { keyBuffer in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBuffer.baseAddress?.assumingMemoryBound(to: Int8.self), passwordBytes.count,
                        saltBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self), salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA1), 1003,
                        keyBuffer.baseAddress?.assumingMemoryBound(to: UInt8.self), keyCount
                    )
                }
            }
        }
        guard status == kCCSuccess else { throw ZhipuQuotaReadError.cookieReadFailed }
        return Data(key)
    }

    private static func decryptCookie(_ record: ZhipuCookieRecord, with key: Data) throws -> String? {
        guard let encrypted = Data(zhipuHexString: record.encryptedHex),
              encrypted.starts(with: Data("v10".utf8)) else { return nil }
        let ciphertext = encrypted.dropFirst(3)
        let iv = [UInt8](repeating: 0x20, count: kCCBlockSizeAES128)
        var plaintext = [UInt8](repeating: 0, count: ciphertext.count + kCCBlockSizeAES128)
        let capacity = plaintext.count
        var decryptedLength = 0
        let status = key.withUnsafeBytes { keyBuffer in
            iv.withUnsafeBytes { ivBuffer in
                ciphertext.withUnsafeBytes { cipherBuffer in
                    plaintext.withUnsafeMutableBytes { plainBuffer in
                        CCCrypt(
                            CCOperation(kCCDecrypt), CCAlgorithm(kCCAlgorithmAES), CCOptions(kCCOptionPKCS7Padding),
                            keyBuffer.baseAddress, key.count, ivBuffer.baseAddress,
                            cipherBuffer.baseAddress, ciphertext.count,
                            plainBuffer.baseAddress, capacity, &decryptedLength
                        )
                    }
                }
            }
        }
        guard status == kCCSuccess else { return nil }
        let decrypted = Data(plaintext.prefix(decryptedLength))
        let domainHash = Data(SHA256.hash(data: Data(record.host.utf8)))
        guard decrypted.starts(with: domainHash) else { return nil }
        return String(data: decrypted.dropFirst(domainHash.count), encoding: .utf8)
    }

    private static func successCode(_ value: Any?) -> Bool {
        guard let code = number(value) else { return false }
        return code == 0 || code == 200
    }

    private static func number(_ value: Any?) -> Double? {
        if let number = value as? NSNumber { return number.doubleValue }
        if let text = value as? String {
            return Double(text.replacingOccurrences(of: ",", with: ""))
        }
        return nil
    }

    private static func string(_ value: Any?) -> String? {
        if let value = value as? String { return value }
        if let value = value as? NSNumber { return value.stringValue }
        return nil
    }
}

private struct ZhipuCookieRecord {
    let host: String
    let path: String
    let name: String
    let plainValue: String
    let encryptedHex: String
}

private extension Data {
    init?(zhipuHexString: String) {
        guard zhipuHexString.count.isMultiple(of: 2) else { return nil }
        var bytes: [UInt8] = []
        bytes.reserveCapacity(zhipuHexString.count / 2)
        var index = zhipuHexString.startIndex
        while index < zhipuHexString.endIndex {
            let next = zhipuHexString.index(index, offsetBy: 2)
            guard let byte = UInt8(zhipuHexString[index..<next], radix: 16) else { return nil }
            bytes.append(byte)
            index = next
        }
        self.init(bytes)
    }
}

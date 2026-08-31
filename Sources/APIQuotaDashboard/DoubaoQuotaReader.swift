import CommonCrypto
import CryptoKit
import Foundation
import Security

struct DoubaoQuotaSummary: Equatable {
    let planName: String?
    let currentPeriod: String
    let lastSevenDays: String
    let currentPeriodRemaining: Double
    let lastSevenDaysRemaining: Double
    let resetHint: String?

    var menuBarTitle: String { currentPeriod }

    var rows: [(String, String)] {
        var result: [(String, String)] = []
        if let planName, !planName.isEmpty {
            result.append(("订阅", planName))
        }
        result.append(("近 7 天剩余", lastSevenDays))
        result.append(("5 小时剩余", currentPeriod))
        if let resetHint, !resetHint.isEmpty {
            result.append(("5h 重置", resetHint))
        }
        return result
    }
}

enum DoubaoQuotaReadError: LocalizedError {
    case clientNotInstalled
    case sessionUnavailable
    case keychainAccessDenied
    case cookieReadFailed
    case invalidCookie
    case requestFailed
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .clientNotInstalled:
            return "未检测到豆包客户端"
        case .sessionUnavailable:
            return "未找到豆包登录会话；请先在豆包客户端登录"
        case .keychainAccessDenied:
            return "无法读取本机豆包登录会话；请允许 API 额度看板访问钥匙串后重试"
        case .cookieReadFailed:
            return "无法读取本机豆包登录会话"
        case .invalidCookie:
            return "豆包登录会话已失效；请在豆包客户端重新登录后重试"
        case .requestFailed:
            return "豆包额度查询失败，请稍后重试"
        case .invalidResponse:
            return "豆包额度接口未返回可用额度数据"
        }
    }
}

private struct DoubaoQuotaResponse: Decodable {
    let code: Int?
    let data: DataBody?

    struct DataBody: Decodable {
        let currentSubscription: Subscription?
        let windowLimitSection: WindowLimitSection?

        enum CodingKeys: String, CodingKey {
            case currentSubscription = "current_subscription"
            case windowLimitSection = "window_limit_section"
        }
    }

    struct Subscription: Decodable { let display: Display? }

    struct Display: Decodable {
        let shortName: String?
        let productName: String?

        enum CodingKeys: String, CodingKey {
            case shortName = "short_name"
            case productName = "product_name"
        }
    }

    struct WindowLimitSection: Decodable {
        let windowLimitGroups: [WindowLimitGroup]?

        enum CodingKeys: String, CodingKey { case windowLimitGroups = "window_limit_groups" }
    }

    struct WindowLimitGroup: Decodable {
        let windowLimits: [WindowLimit]?

        enum CodingKeys: String, CodingKey { case windowLimits = "window_limits" }
    }

    struct WindowLimit: Decodable {
        let windowType: Int?
        let usedPercent: Double?
        let lessThanOnePercent: Bool?
        let endTime: Double?

        enum CodingKeys: String, CodingKey {
            case windowType = "window_type"
            case usedPercent = "used_percent"
            case lessThanOnePercent = "less_than_one_percent"
            case endTime = "end_time"
        }
    }
}

/// Reads the logged-in Doubao desktop session only from this Mac. The session
/// never leaves the device except as the Cookie header of the official
/// doubao.com quota request, and is never written to this app's configuration.
enum DoubaoQuotaReader {
    private static let cookieDatabaseRelativePath = "Library/Application Support/Doubao/Default/Cookies"
    private static let safeStorageService = "Doubao Safe Storage"
    private static let safeStorageAccount = "Doubao"
    private static let quotaURL = URL(string: "https://www.doubao.com/alice/commerce/sale/subscription/quota/summary/")!
    private static let recordSeparator = "\u{1F}"
    private static let windowsEpochOffset: TimeInterval = 11_644_473_600

    static func fetch(session: URLSession = .shared) async throws -> DoubaoQuotaSummary {
        guard FileManager.default.fileExists(atPath: "/Applications/Doubao.app")
                || FileManager.default.fileExists(atPath: "/Applications/豆包.app") else {
            throw DoubaoQuotaReadError.clientNotInstalled
        }

        let cookieHeader = try await Task.detached(priority: .userInitiated) {
            try sessionCookieHeader()
        }.value

        var request = URLRequest(url: quotaURL)
        request.httpMethod = "POST"
        request.httpBody = Data("{}".utf8)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
        request.setValue("https://www.doubao.com", forHTTPHeaderField: "Origin")
        request.setValue("https://www.doubao.com/member/quota-management", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 Chrome/147 Safari/537.36", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200 ... 299).contains(httpResponse.statusCode) else {
            throw DoubaoQuotaReadError.requestFailed
        }
        return try parseQuotaResponse(data)
    }

    static func parseQuotaResponse(_ data: Data, now: Date = Date()) throws -> DoubaoQuotaSummary {
        let response = try JSONDecoder().decode(DoubaoQuotaResponse.self, from: data)
        let limits = (response.data?.windowLimitSection?.windowLimitGroups ?? [])
            .compactMap(\.windowLimits)
            .flatMap { $0 }
        guard response.code == 0,
              let current = limits.first(where: { $0.windowType == 1 }),
              let week = limits.first(where: { $0.windowType == 2 }) else {
            throw DoubaoQuotaReadError.invalidResponse
        }

        let planName = response.data?.currentSubscription?.display?.shortName
            ?? response.data?.currentSubscription?.display?.productName
        return DoubaoQuotaSummary(
            planName: planName,
            currentPeriod: remainingText(for: current),
            lastSevenDays: remainingText(for: week),
            currentPeriodRemaining: remainingPercent(for: current),
            lastSevenDaysRemaining: remainingPercent(for: week),
            resetHint: resetText(for: current, now: now)
        )
    }

    private static func sessionCookieHeader() throws -> String {
        let databaseURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(cookieDatabaseRelativePath)
        guard FileManager.default.fileExists(atPath: databaseURL.path) else {
            throw DoubaoQuotaReadError.sessionUnavailable
        }

        let password = try safeStoragePassword()
        let key = try deriveKey(from: password)
        let records = try readCookieRecords(from: databaseURL)
        let cookies = try records.compactMap { record -> String? in
            guard quotaURL.path.hasPrefix(record.path),
                  let value = try decryptCookie(record, with: key),
                  !value.isEmpty else {
                return nil
            }
            return "\(record.name)=\(value)"
        }
        guard !cookies.isEmpty else { throw DoubaoQuotaReadError.sessionUnavailable }
        return cookies.joined(separator: "; ")
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
            if status == errSecItemNotFound { throw DoubaoQuotaReadError.sessionUnavailable }
            throw DoubaoQuotaReadError.keychainAccessDenied
        }
        return password
    }

    private static func readCookieRecords(from databaseURL: URL) throws -> [CookieRecord] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
        let now = Int64((Date().timeIntervalSince1970 + windowsEpochOffset) * 1_000_000)
        let sql = """
        SELECT host_key, path, name, hex(encrypted_value)
        FROM cookies
        WHERE host_key IN ('.doubao.com', 'www.doubao.com')
          AND length(encrypted_value) > 3
          AND (expires_utc = 0 OR expires_utc > \(now))
        ORDER BY length(path) DESC;
        """
        process.arguments = ["-readonly", "-separator", recordSeparator, databaseURL.path, sql]
        let output = Pipe()
        process.standardOutput = output
        process.standardError = Pipe()
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { throw DoubaoQuotaReadError.cookieReadFailed }

        let text = String(data: output.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        return text.split(whereSeparator: \.isNewline).compactMap { line in
            let parts = line.components(separatedBy: recordSeparator)
            guard parts.count == 4 else { return nil }
            return CookieRecord(host: parts[0], path: parts[1], name: parts[2], encryptedHex: parts[3])
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
        guard status == kCCSuccess else { throw DoubaoQuotaReadError.cookieReadFailed }
        return Data(key)
    }

    private static func decryptCookie(_ record: CookieRecord, with key: Data) throws -> String? {
        guard let encrypted = Data(hexString: record.encryptedHex),
              encrypted.starts(with: Data("v10".utf8)) else {
            return nil
        }
        let ciphertext = encrypted.dropFirst(3)
        let iv = [UInt8](repeating: 0x20, count: kCCBlockSizeAES128)
        var plaintext = [UInt8](repeating: 0, count: ciphertext.count + kCCBlockSizeAES128)
        let plaintextCapacity = plaintext.count
        var decryptedLength = 0
        let status = key.withUnsafeBytes { keyBuffer in
            iv.withUnsafeBytes { ivBuffer in
                ciphertext.withUnsafeBytes { cipherBuffer in
                    plaintext.withUnsafeMutableBytes { plainBuffer in
                        CCCrypt(
                            CCOperation(kCCDecrypt), CCAlgorithm(kCCAlgorithmAES), CCOptions(kCCOptionPKCS7Padding),
                            keyBuffer.baseAddress, key.count, ivBuffer.baseAddress,
                            cipherBuffer.baseAddress, ciphertext.count,
                            plainBuffer.baseAddress, plaintextCapacity, &decryptedLength
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

    private static func remainingPercent(for limit: DoubaoQuotaResponse.WindowLimit) -> Double {
        let used = min(100, max(0, limit.usedPercent ?? 0))
        return 100 - used
    }

    private static func remainingText(for limit: DoubaoQuotaResponse.WindowLimit) -> String {
        if limit.lessThanOnePercent == true { return ">99%" }
        return percentText(remainingPercent(for: limit))
    }

    private static func resetText(for limit: DoubaoQuotaResponse.WindowLimit, now: Date) -> String? {
        guard let rawTime = limit.endTime, rawTime > 0 else { return nil }
        let interval = rawTime > 10_000_000_000 ? rawTime / 1_000 : rawTime
        let date = Date(timeIntervalSince1970: interval)
        guard date > now else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }

    private static func percentText(_ value: Double) -> String {
        value.rounded() == value ? "\(Int(value))%" : String(format: "%.1f%%", value)
    }
}

private struct CookieRecord {
    let host: String
    let path: String
    let name: String
    let encryptedHex: String
}

private extension Data {
    init?(hexString: String) {
        guard hexString.count.isMultiple(of: 2) else { return nil }
        var bytes: [UInt8] = []
        bytes.reserveCapacity(hexString.count / 2)
        var index = hexString.startIndex
        while index < hexString.endIndex {
            let next = hexString.index(index, offsetBy: 2)
            guard let byte = UInt8(hexString[index..<next], radix: 16) else { return nil }
            bytes.append(byte)
            index = next
        }
        self.init(bytes)
    }
}

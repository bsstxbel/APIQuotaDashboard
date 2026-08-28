import XCTest
@testable import APIQuotaDashboard

final class BalanceScaleTests: XCTestCase {
    func testTenColorStepsUseExpectedBoundaries() {
        XCTAssertEqual(BalanceService.tenStepIndex(value: -1, max: 100), 0)
        XCTAssertEqual(BalanceService.tenStepIndex(value: 0, max: 100), 0)
        XCTAssertEqual(BalanceService.tenStepIndex(value: 9.99, max: 100), 0)
        XCTAssertEqual(BalanceService.tenStepIndex(value: 10, max: 100), 1)
        XCTAssertEqual(BalanceService.tenStepIndex(value: 89.99, max: 100), 8)
        XCTAssertEqual(BalanceService.tenStepIndex(value: 90, max: 100), 9)
        XCTAssertEqual(BalanceService.tenStepIndex(value: 100, max: 100), 9)
        XCTAssertEqual(BalanceService.tenStepIndex(value: 120, max: 100), 9)
    }

    func testBalanceIncreaseResetsScaleToCurrentBalance() {
        XCTAssertEqual(
            BalanceService.updatedDeepSeekScale(current: 80, previous: 40, scaleMax: 100),
            80
        )
    }

    func testBalanceDecreaseKeepsExistingScale() {
        XCTAssertEqual(
            BalanceService.updatedDeepSeekScale(current: 30, previous: 40, scaleMax: 80),
            80
        )
    }

    func testFirstPositiveBalanceInitializesScale() {
        XCTAssertEqual(
            BalanceService.updatedDeepSeekScale(current: 25, previous: -1.3, scaleMax: nil),
            25
        )
    }

    func testRefreshIntervalOptionsAndDefault() {
        XCTAssertEqual(BalanceService.allowedRefreshIntervals, [15, 30, 60, 120, 300])
        XCTAssertEqual(BalanceService.normalizedRefreshInterval(nil), 120)
        XCTAssertEqual(BalanceService.normalizedRefreshInterval(30), 30)
        XCTAssertEqual(BalanceService.normalizedRefreshInterval(999), 999)
        XCTAssertEqual(BalanceService.normalizedRefreshInterval(1), 120)
        XCTAssertEqual(BalanceService.normalizedRefreshInterval(100_000), 120)
    }

    func testVolcSubscriptionPrefersWeeklyForMenuBar() {
        let summary = VolcPlanSummary(items: [
            VolcPlanItem(
                product: "CodingPlan",
                edition: "personal",
                tier: "pro",
                subscribed: true,
                periods: [
                    VolcPlanPeriod(label: "5h", used: 20, total: 100, percent: 20, resetAt: nil),
                    VolcPlanPeriod(label: "weekly", used: 35, total: 100, percent: 35, resetAt: nil)
                ]
            )
        ])
        XCTAssertEqual(summary.primaryPeriod?.label, "weekly")
        XCTAssertEqual(summary.primaryPeriod?.remainingPercent, 65)
        XCTAssertTrue(BalanceService.hasFiveHourQuota(
            provider: .volcengine,
            codexSummary: nil,
            volcPlanSummary: summary
        ))
        XCTAssertFalse(BalanceService.hasFiveHourQuota(
            provider: .deepseek,
            codexSummary: nil,
            volcPlanSummary: summary
        ))
    }

    func testCodexFiveHourDisplayAvailabilityFollowsReturnedLimit() {
        let summary = CodexSummary(
            planType: "plus",
            weeklyRemaining: 80,
            weeklyResetAt: nil,
            fiveHourRemaining: 60,
            fiveHourResetAt: nil,
            limitReached: false,
            lastUpdated: nil
        )
        XCTAssertTrue(BalanceService.hasFiveHourQuota(
            provider: .codex,
            codexSummary: summary,
            volcPlanSummary: nil
        ))
        XCTAssertFalse(BalanceService.hasFiveHourQuota(
            provider: .codex,
            codexSummary: nil,
            volcPlanSummary: nil
        ))
    }

    func testProviderDescriptionsMatchVerifiedCapability() {
        XCTAssertTrue(Provider.kimi.queryAvailabilityDescription.contains("API Key"))
        XCTAssertTrue(Provider.claude.queryAvailabilityDescription.contains("组织管理员"))
        XCTAssertTrue(Provider.gemini.queryAvailabilityDescription.contains("AI Studio"))
        XCTAssertTrue(Provider.openai.queryAvailabilityDescription.contains("Costs API"))
        XCTAssertTrue(Provider.openrouter.queryAvailabilityDescription.contains("Management Key"))
        XCTAssertTrue(Provider.siliconflow.queryAvailabilityDescription.contains("总余额"))
    }

    func testOnlyActuallyQueryableProvidersAppearInSettings() {
        XCTAssertEqual(
            Provider.queryableCases,
            [
                .deepseek, .volcengine, .codex, .claude, .gemini, .kimi, .qwen, .minimax,
                .openai, .openrouter, .siliconflow
            ]
        )
        XCTAssertTrue(Provider.kimi.supportsQuotaQuery)
        XCTAssertTrue(Provider.claude.supportsQuotaQuery)
        XCTAssertFalse(Provider.doubao.supportsQuotaQuery)
        XCTAssertFalse(Provider.zhipu.supportsQuotaQuery)
        XCTAssertTrue(Provider.kimi.requiresAccountSetupForDisplay)
        XCTAssertTrue(Provider.gemini.requiresAccountSetupForDisplay)
        XCTAssertTrue(Provider.openrouter.requiresAccountSetupForDisplay)
        XCTAssertFalse(Provider.codex.requiresAccountSetupForDisplay)
    }

    func testStatusItemWidthShrinksAndRemainsBounded() {
        XCTAssertEqual(AppDelegate.initialStatusItemWidth, 52)
        XCTAssertEqual(AppDelegate.statusItemAutosaveName, "APIQuotaDashboardQuotaV3")
        XCTAssertEqual(AppDelegate.statusItemBaselineOffset, 0)
        XCTAssertEqual(AppDelegate.statusItemLength(contentWidth: 1), 18)
        XCTAssertEqual(AppDelegate.statusItemLength(contentWidth: 20.2), 23)
        XCTAssertEqual(AppDelegate.statusItemLength(contentWidth: 200), 96)
    }

    func testAllApplicationIconAppearancesRemainAvailable() {
        XCTAssertEqual(
            Set(IconAppearance.allCases.map(\.rawValue)),
            Set(["white", "black", "transparent", "system"])
        )
    }

    func testProxyParserAcceptsSupportedFormats() {
        let socks = ProxySettings.parse("socks5://127.0.0.1:1080")
        XCTAssertEqual(socks?.host, "127.0.0.1")
        XCTAssertEqual(socks?.port, 1080)
        XCTAssertEqual(socks?.type, "socks5")

        let implicit = ProxySettings.parse("proxy.example.com:7890")
        XCTAssertEqual(implicit?.host, "proxy.example.com")
        XCTAssertEqual(implicit?.type, "socks5")

        let http = ProxySettings.parse("https://localhost:8443")
        XCTAssertEqual(http?.type, "http")
    }

    func testProxyParserRejectsUnsafeOrAmbiguousFormats() {
        XCTAssertNil(ProxySettings.parse(""))
        XCTAssertNil(ProxySettings.parse("ftp://localhost:21"))
        XCTAssertNil(ProxySettings.parse("http://localhost"))
        XCTAssertNil(ProxySettings.parse("http://user:password@localhost:8080"))
        XCTAssertNil(ProxySettings.parse("http://localhost:70000"))
        XCTAssertNil(ProxySettings.parse("http://localhost:8080/path"))
    }

    func testRefreshCoalescingAllowsOnlyForcedReplacement() {
        XCTAssertTrue(BalanceService.shouldStartRefresh(isRefreshing: false, force: false))
        XCTAssertFalse(BalanceService.shouldStartRefresh(isRefreshing: true, force: false))
        XCTAssertTrue(BalanceService.shouldStartRefresh(isRefreshing: true, force: true))
    }

    func testStaleFetchResultsAreRejected() {
        XCTAssertTrue(BalanceService.shouldApplyFetchResult(
            requestedProvider: .deepseek,
            currentProvider: .deepseek,
            generation: 4,
            currentGeneration: 4
        ))
        XCTAssertFalse(BalanceService.shouldApplyFetchResult(
            requestedProvider: .deepseek,
            currentProvider: .codex,
            generation: 4,
            currentGeneration: 4
        ))
        XCTAssertFalse(BalanceService.shouldApplyFetchResult(
            requestedProvider: .deepseek,
            currentProvider: .deepseek,
            generation: 3,
            currentGeneration: 4
        ))
    }

    func testErrorSanitizerRemovesCommonSecretShapes() {
        let raw = "Authorization: Bearer sk-proj-abcdefghijklmnop\napi_key=secret-value"
        let safe = BalanceService.sanitizedErrorMessage(raw)
        XCTAssertFalse(safe.contains("abcdefghijklmnop"))
        XCTAssertFalse(safe.contains("secret-value"))
        XCTAssertTrue(safe.contains("已隐藏"))
        XCTAssertFalse(safe.contains("\n"))
    }

    func testHTTPErrorMessagesAreActionableAndSanitized() throws {
        let data = try JSONSerialization.data(withJSONObject: [
            "error": ["message": "bad Bearer sk-test-abcdefghijkl"]
        ])
        let message = BalanceService.httpErrorMessage(statusCode: 401, data: data)
        XCTAssertTrue(message.contains("凭证无效"))
        XCTAssertFalse(message.contains("abcdefghijkl"))
        XCTAssertEqual(
            BalanceService.httpErrorMessage(statusCode: 429, data: Data()),
            "请求过于频繁，请稍后重试"
        )
    }

    func testTransientNetworkFailuresAreRetryable() {
        XCTAssertTrue(BalanceService.isTransientNetworkError(URLError(.timedOut)))
        XCTAssertTrue(BalanceService.isTransientNetworkError(URLError(.networkConnectionLost)))
        XCTAssertFalse(BalanceService.isTransientNetworkError(URLError(.userAuthenticationRequired)))
        XCTAssertFalse(BalanceService.isTransientNetworkError(NSError(domain: "test", code: 1)))
    }

    func testRelativeFreshnessDescriptionsUseReadableBuckets() {
        let now = Date(timeIntervalSince1970: 10_000)
        XCTAssertEqual(BalanceService.relativeAgeDescription(since: now, now: now), "刚刚")
        XCTAssertEqual(BalanceService.relativeAgeDescription(since: now.addingTimeInterval(-45), now: now), "45 秒前")
        XCTAssertEqual(BalanceService.relativeAgeDescription(since: now.addingTimeInterval(-125), now: now), "2 分钟前")
        XCTAssertEqual(BalanceService.relativeAgeDescription(since: now.addingTimeInterval(-7_300), now: now), "2 小时前")
    }

    func testProviderShortNamesAndOfficialDashboardsAreAvailable() {
        for provider in Provider.queryableCases {
            XCTAssertFalse(provider.shortName.isEmpty)
            XCTAssertEqual(provider.dashboardURL?.scheme, "https")
        }
    }

    func testMenuBarDisplayModesRemainStableForConfigCompatibility() {
        XCTAssertEqual(MenuBarDisplayMode.allCases.map(\.rawValue), ["value_only", "provider_and_value"])
        XCTAssertEqual(MenuBarDisplayMode.valueOnly.displayName, "仅显示额度")
    }

    func testMenuBarQuotaDisplayModesAndFallbacks() {
        XCTAssertEqual(
            MenuBarQuotaDisplayMode.allCases.map(\.rawValue),
            ["five_hour_only", "total_only", "all"]
        )
        XCTAssertEqual(
            BalanceService.quotaLineValues(total: "82%", fiveHour: "64%", mode: .all),
            ["82%", "64%"]
        )
        XCTAssertEqual(
            BalanceService.quotaLineValues(total: "82%", fiveHour: "64%", mode: .fiveHourOnly),
            ["64%"]
        )
        XCTAssertEqual(
            BalanceService.quotaLineValues(total: "82%", fiveHour: "64%", mode: .totalOnly),
            ["82%"]
        )
        XCTAssertEqual(
            BalanceService.quotaLineValues(total: "82%", fiveHour: nil, mode: .fiveHourOnly),
            ["82%"]
        )
    }

    func testLogRotationHasBoundedSize() {
        XCTAssertEqual(BalanceService.maximumLogSize, 512 * 1_024)
    }

}

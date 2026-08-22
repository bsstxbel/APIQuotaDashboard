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
    }

    func testProviderDescriptionsMatchVerifiedCapability() {
        XCTAssertTrue(Provider.kimi.queryAvailabilityDescription.contains("API Key"))
        XCTAssertTrue(Provider.claude.queryAvailabilityDescription.contains("组织管理员"))
        XCTAssertTrue(Provider.gemini.queryAvailabilityDescription.contains("AI Studio"))
    }

    func testOnlyActuallyQueryableProvidersAppearInSettings() {
        XCTAssertEqual(
            Provider.queryableCases,
            [.deepseek, .volcengine, .codex, .claude, .gemini, .kimi, .qwen, .minimax]
        )
        XCTAssertTrue(Provider.kimi.supportsQuotaQuery)
        XCTAssertTrue(Provider.claude.supportsQuotaQuery)
        XCTAssertFalse(Provider.doubao.supportsQuotaQuery)
        XCTAssertFalse(Provider.zhipu.supportsQuotaQuery)
        XCTAssertTrue(Provider.kimi.requiresAccountSetupForDisplay)
        XCTAssertTrue(Provider.gemini.requiresAccountSetupForDisplay)
        XCTAssertFalse(Provider.codex.requiresAccountSetupForDisplay)
    }

    func testStatusItemWidthShrinksAndRemainsBounded() {
        XCTAssertEqual(AppDelegate.statusItemLength(contentWidth: 1), 18)
        XCTAssertEqual(AppDelegate.statusItemLength(contentWidth: 20.2), 31)
        XCTAssertEqual(AppDelegate.statusItemLength(contentWidth: 200), 96)
    }

    func testAllApplicationIconAppearancesRemainAvailable() {
        XCTAssertEqual(
            Set(IconAppearance.allCases.map(\.rawValue)),
            Set(["white", "black", "transparent", "system"])
        )
    }
}

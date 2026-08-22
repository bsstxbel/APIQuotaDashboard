import AppKit

final class SettingsWindowController: NSWindowController {
    private let service: BalanceService
    private var providerButtons: [Provider: NSButton] = [:]
    private let providerStatus = NSTextField(labelWithString: "")

    private let deepSeekPopup = NSPopUpButton()
    private let deepSeekNameField = NSTextField()
    private let deepSeekKeyField = NSSecureTextField()

    private let volcProfilePopup = NSPopUpButton()
    private let volcStatus = NSTextField(labelWithString: "")
    private let codexStatus = NSTextField(labelWithString: "")
    private var credentialFields: [Provider: NSSecureTextField] = [:]
    private var credentialStatuses: [Provider: NSTextField] = [:]
    private let qwenWorkspaceField = NSTextField()

    private let launchAtLoginButton = NSButton(checkboxWithTitle: "开机自动启动", target: nil, action: nil)
    private let systemProxyButton = NSButton(checkboxWithTitle: "自动使用 macOS 系统代理", target: nil, action: nil)
    private let manualProxyField = NSTextField()
    private let iconPopup = NSPopUpButton()
    private let refreshPopup = NSPopUpButton()
    private let customRefreshField = NSTextField()

    init(service: BalanceService) {
        self.service = service
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 650),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "设置"
        window.center()
        super.init(window: window)
        buildInterface()
        reloadAll()
    }

    required init?(coder: NSCoder) { nil }

    private func buildInterface() {
        guard let content = window?.contentView else { return }
        let tabs = NSTabView()
        tabs.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(tabs)
        NSLayoutConstraint.activate([
            tabs.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 18),
            tabs.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -18),
            tabs.topAnchor.constraint(equalTo: content.topAnchor, constant: 18),
            tabs.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -18)
        ])

        let general = NSTabViewItem(identifier: "general")
        general.label = "通用"
        general.view = makeGeneralView()
        tabs.addTabViewItem(general)

        let providers = NSTabViewItem(identifier: "providers")
        providers.label = "提供方"
        providers.view = makeProvidersView()
        tabs.addTabViewItem(providers)

        let accounts = NSTabViewItem(identifier: "accounts")
        accounts.label = "账号"
        accounts.view = makeAccountsView()
        tabs.addTabViewItem(accounts)
    }

    private func makeGeneralView() -> NSView {
        let stack = baseStack()

        launchAtLoginButton.target = self
        launchAtLoginButton.action = #selector(launchAtLoginChanged)
        stack.addArrangedSubview(launchAtLoginButton)

        systemProxyButton.target = self
        systemProxyButton.action = #selector(proxyChanged)
        stack.addArrangedSubview(systemProxyButton)

        manualProxyField.placeholderString = "手动代理（可选），例如 socks5://127.0.0.1:1080"
        manualProxyField.target = self
        manualProxyField.action = #selector(proxyChanged)
        stack.addArrangedSubview(formRow(label: "手动代理", control: manualProxyField))

        iconPopup.addItems(withTitles: IconAppearance.allCases.map(\.displayName))
        iconPopup.target = self
        iconPopup.action = #selector(iconChanged)
        stack.addArrangedSubview(formRow(label: "图标颜色", control: iconPopup))

        refreshPopup.addItems(withTitles: BalanceService.allowedRefreshIntervals.map(refreshTitle))
        refreshPopup.target = self
        refreshPopup.action = #selector(refreshPresetChanged)
        stack.addArrangedSubview(formRow(label: "刷新档位", control: refreshPopup))

        customRefreshField.placeholderString = "5–86400 秒"
        let applyCustom = NSButton(title: "应用", target: self, action: #selector(applyCustomRefresh))
        let customRow = NSStackView(views: [customRefreshField, applyCustom])
        customRow.orientation = .horizontal
        customRow.spacing = 8
        stack.addArrangedSubview(formRow(label: "自定义刷新", control: customRow))

        let hint = NSTextField(wrappingLabelWithString: "系统代理会用于 Codex、DeepSeek 以及后续需要网络代理的提供方；手动代理仅在关闭系统代理时使用。")
        hint.textColor = .secondaryLabelColor
        stack.addArrangedSubview(hint)

        let positionHint = NSTextField(wrappingLabelWithString: "菜单栏位置：按住 Command（⌘）拖动额度文字到最左侧，macOS 会自动记住该位置。系统不允许应用自行强制排序。")
        positionHint.textColor = .secondaryLabelColor
        stack.addArrangedSubview(positionHint)
        return wrapped(stack)
    }

    private func makeProvidersView() -> NSView {
        let stack = baseStack()
        let intro = NSTextField(wrappingLabelWithString: "选择显示在“切换提供方”中的项目。需要 API Key 或网页登录的提供方，会在“账号”页完成配置后出现在这里。")
        intro.textColor = .secondaryLabelColor
        stack.addArrangedSubview(intro)

        for provider in Provider.queryableCases {
            let button = NSButton(checkboxWithTitle: provider.displayName, target: nil, action: nil)
            providerButtons[provider] = button
            stack.addArrangedSubview(button)
        }

        let actions = NSStackView()
        actions.orientation = .horizontal
        actions.spacing = 10
        actions.addArrangedSubview(NSButton(title: "保存显示项目", target: self, action: #selector(saveProviders)))
        stack.addArrangedSubview(actions)
        providerStatus.textColor = .secondaryLabelColor
        stack.addArrangedSubview(providerStatus)
        return wrapped(stack)
    }

    private func makeAccountsView() -> NSView {
        let stack = baseStack()
        stack.addArrangedSubview(sectionTitle("DeepSeek"))

        let deepSeekMethod = NSTextField(wrappingLabelWithString: "查询方式：使用 DeepSeek 开放平台 API Key 查询可用、充值和赠送余额。密钥只保存在 macOS 钥匙串。")
        deepSeekMethod.textColor = .secondaryLabelColor
        stack.addArrangedSubview(deepSeekMethod)

        deepSeekPopup.target = self
        deepSeekPopup.action = #selector(deepSeekSelectionChanged)
        stack.addArrangedSubview(formRow(label: "当前账号", control: deepSeekPopup))

        deepSeekNameField.placeholderString = "账号名称"
        stack.addArrangedSubview(formRow(label: "名称", control: deepSeekNameField))
        deepSeekKeyField.placeholderString = "DeepSeek API Key（存入钥匙串）"
        stack.addArrangedSubview(formRow(label: "API Key", control: deepSeekKeyField))

        let dsActions = NSStackView()
        dsActions.orientation = .horizontal
        dsActions.spacing = 10
        dsActions.addArrangedSubview(NSButton(title: "保存并切换", target: self, action: #selector(saveDeepSeekAccount)))
        dsActions.addArrangedSubview(NSButton(title: "删除当前账号", target: self, action: #selector(deleteDeepSeekAccount)))
        stack.addArrangedSubview(dsActions)

        stack.addArrangedSubview(sectionTitle("火山引擎"))
        let volcMethod = NSTextField(wrappingLabelWithString: "登录方式：使用 arkcli 官方 SSO 登录并选择 Profile；可查询 Agent/Coding Plan 与免费模型额度。")
        volcMethod.textColor = .secondaryLabelColor
        stack.addArrangedSubview(volcMethod)
        stack.addArrangedSubview(formRow(label: "当前 Profile", control: volcProfilePopup))

        let volcActions = NSStackView()
        volcActions.orientation = .horizontal
        volcActions.spacing = 10
        volcActions.addArrangedSubview(NSButton(title: "切换 Profile", target: self, action: #selector(switchVolcProfile)))
        volcActions.addArrangedSubview(NSButton(title: "刷新列表", target: self, action: #selector(refreshVolcProfiles)))
        volcActions.addArrangedSubview(NSButton(title: "登录 / 更换账号", target: self, action: #selector(loginVolc)))
        stack.addArrangedSubview(volcActions)
        volcStatus.textColor = .secondaryLabelColor
        stack.addArrangedSubview(volcStatus)

        stack.addArrangedSubview(sectionTitle("Codex"))
        let codexMethod = NSTextField(wrappingLabelWithString: "登录方式：使用本机 Codex 的 ChatGPT 登录状态；切换到 Codex 后自动查询每周和 5 小时额度。")
        codexMethod.textColor = .secondaryLabelColor
        stack.addArrangedSubview(codexMethod)
        codexStatus.textColor = .secondaryLabelColor
        stack.addArrangedSubview(codexStatus)

        addCredentialSection(
            to: stack,
            provider: .kimi,
            method: "查询方式：输入 Moonshot API Key，查询 Kimi 开放平台的可用、现金和代金券余额。"
        )

        addCredentialSection(
            to: stack,
            provider: .qwen,
            method: "查询方式：输入 DashScope API Key 和阿里云百炼 Workspace ID，查询各模型的请求与 Token 限额。",
            needsWorkspace: true
        )

        addCredentialSection(
            to: stack,
            provider: .minimax,
            method: "查询方式：输入 MiniMax Token Plan Key，查询 5 小时、周额度及套餐剩余。"
        )

        addCredentialSection(
            to: stack,
            provider: .claude,
            method: "查询方式：输入组织管理员 Admin API Key，查询最近 7 天组织 API 用量；个人 Claude 订阅不支持此接口。"
        )

        stack.addArrangedSubview(sectionTitle("Gemini"))
        let geminiMethod = NSTextField(wrappingLabelWithString: "查询方式：登录 Google AI Studio，在 Dashboard → Usage / Billing 查看 API 用量与余额。")
        geminiMethod.textColor = .secondaryLabelColor
        stack.addArrangedSubview(geminiMethod)
        stack.addArrangedSubview(NSButton(title: "打开 Google AI Studio", target: self, action: #selector(openGeminiUsage)))
        let geminiConfirmed = NSButton(title: "我已登录，加入显示提供方", target: self, action: #selector(confirmGeminiLogin))
        let geminiHide = NSButton(title: "取消登录标记", target: self, action: #selector(clearGeminiLogin))
        let geminiActions = NSStackView(views: [geminiConfirmed, geminiHide])
        geminiActions.orientation = .horizontal
        geminiActions.spacing = 10
        stack.addArrangedSubview(geminiActions)

        return scrollWrapped(stack)
    }

    private func addCredentialSection(
        to stack: NSStackView,
        provider: Provider,
        method: String,
        needsWorkspace: Bool = false
    ) {
        stack.addArrangedSubview(sectionTitle(provider.displayName))
        let description = NSTextField(wrappingLabelWithString: method)
        description.textColor = .secondaryLabelColor
        stack.addArrangedSubview(description)

        let field = NSSecureTextField()
        field.placeholderString = provider == .claude ? "Admin API Key（存入钥匙串）" : "API Key（存入钥匙串）"
        credentialFields[provider] = field
        stack.addArrangedSubview(formRow(label: "API Key", control: field))

        if needsWorkspace {
            qwenWorkspaceField.placeholderString = "例如 llm-xxxxxxxx"
            stack.addArrangedSubview(formRow(label: "Workspace ID", control: qwenWorkspaceField))
        }

        let save = NSButton(title: "保存凭证", target: self, action: #selector(saveCredential(_:)))
        save.identifier = NSUserInterfaceItemIdentifier(provider.rawValue)
        let delete = NSButton(title: "删除凭证", target: self, action: #selector(deleteCredential(_:)))
        delete.identifier = NSUserInterfaceItemIdentifier(provider.rawValue)
        let actions = NSStackView(views: [save, delete])
        actions.orientation = .horizontal
        actions.spacing = 10
        stack.addArrangedSubview(actions)

        let status = NSTextField(labelWithString: "")
        status.textColor = .secondaryLabelColor
        credentialStatuses[provider] = status
        stack.addArrangedSubview(status)
    }

    private func baseStack() -> NSStackView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }

    private func wrapped(_ stack: NSStackView) -> NSView {
        let view = NSView()
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -18),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 22)
        ])
        return view
    }

    private func scrollWrapped(_ stack: NSStackView) -> NSView {
        let document = NSView()
        document.translatesAutoresizingMaskIntoConstraints = false
        document.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: document.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: document.trailingAnchor, constant: -18),
            stack.topAnchor.constraint(equalTo: document.topAnchor, constant: 22),
            stack.bottomAnchor.constraint(equalTo: document.bottomAnchor, constant: -22),
            document.widthAnchor.constraint(greaterThanOrEqualToConstant: 540)
        ])

        let scroll = NSScrollView()
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false
        scroll.documentView = document
        return scroll
    }

    private func sectionTitle(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        return label
    }

    private func formRow(label: String, control: NSView) -> NSView {
        let title = NSTextField(labelWithString: label)
        title.alignment = .right
        title.widthAnchor.constraint(equalToConstant: 105).isActive = true
        control.widthAnchor.constraint(greaterThanOrEqualToConstant: 300).isActive = true
        let row = NSStackView(views: [title, control])
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = 10
        return row
    }

    private func refreshTitle(_ seconds: TimeInterval) -> String {
        switch Int(seconds) {
        case 15: return "15 秒"
        case 30: return "30 秒"
        case 60: return "1 分钟"
        case 120: return "2 分钟"
        case 300: return "5 分钟"
        default: return "\(Int(seconds)) 秒"
        }
    }

    private func reloadAll() {
        reloadProviderButtons()
        reloadDeepSeekAccounts()
        launchAtLoginButton.state = LaunchAtLoginManager.isEnabled ? .on : .off
        systemProxyButton.state = service.useSystemProxy ? .on : .off
        manualProxyField.stringValue = service.codexProxy ?? ""
        if let index = IconAppearance.allCases.firstIndex(of: service.iconAppearance) {
            iconPopup.selectItem(at: index)
        }
        if let index = BalanceService.allowedRefreshIntervals.firstIndex(of: service.refreshIntervalSeconds) {
            refreshPopup.selectItem(at: index)
        }
        customRefreshField.stringValue = String(Int(service.refreshIntervalSeconds))
        reloadCodexStatus()
        reloadCredentialStatuses()
        loadVolcProfiles()
    }

    private func reloadProviderButtons() {
        for (provider, button) in providerButtons {
            button.isHidden = !service.providersAvailableForDisplay.contains(provider)
            button.state = service.enabledProviders.contains(provider) ? .on : .off
        }
    }

    private func reloadDeepSeekAccounts() {
        let accounts = service.deepSeekAccounts
        deepSeekPopup.removeAllItems()
        deepSeekPopup.addItems(withTitles: accounts)
        if let selected = service.selectedDeepSeekAccount { deepSeekPopup.selectItem(withTitle: selected) }
    }

    @objc private func launchAtLoginChanged() {
        do {
            try LaunchAtLoginManager.setEnabled(launchAtLoginButton.state == .on)
        } catch {
            showError(error.localizedDescription)
            launchAtLoginButton.state = LaunchAtLoginManager.isEnabled ? .on : .off
        }
    }

    @objc private func proxyChanged() {
        service.setProxyConfiguration(
            useSystem: systemProxyButton.state == .on,
            manualProxy: manualProxyField.stringValue
        )
    }

    @objc private func iconChanged() {
        let index = iconPopup.indexOfSelectedItem
        guard IconAppearance.allCases.indices.contains(index) else { return }
        service.setIconAppearance(IconAppearance.allCases[index])
    }

    @objc private func refreshPresetChanged() {
        let index = refreshPopup.indexOfSelectedItem
        guard BalanceService.allowedRefreshIntervals.indices.contains(index) else { return }
        let seconds = BalanceService.allowedRefreshIntervals[index]
        customRefreshField.stringValue = String(Int(seconds))
        service.setRefreshInterval(seconds)
    }

    @objc private func applyCustomRefresh() {
        guard let seconds = Double(customRefreshField.stringValue), seconds >= 5, seconds <= 86_400 else {
            showError("自定义刷新时间必须在 5–86400 秒之间。")
            return
        }
        service.setRefreshInterval(seconds)
    }

    @objc private func saveProviders() {
        let selected = Provider.queryableCases.filter { providerButtons[$0]?.state == .on }
        service.setEnabledProviders(selected)
        reloadAll()
        providerStatus.stringValue = "已保存"
    }

    @objc private func deepSeekSelectionChanged() {
        if let account = deepSeekPopup.titleOfSelectedItem { service.selectDeepSeekAccount(account) }
    }

    @objc private func saveDeepSeekAccount() {
        guard service.saveDeepSeekAccount(name: deepSeekNameField.stringValue, apiKey: deepSeekKeyField.stringValue) else {
            showError("账号名称或 API Key 无效，或者钥匙串写入失败。")
            return
        }
        deepSeekKeyField.stringValue = ""
        reloadDeepSeekAccounts()
    }

    @objc private func deleteDeepSeekAccount() {
        guard let account = deepSeekPopup.titleOfSelectedItem else { return }
        if service.deleteDeepSeekAccount(account) { reloadDeepSeekAccounts() }
    }

    @objc private func refreshVolcProfiles() { loadVolcProfiles() }

    private func loadVolcProfiles() {
        volcStatus.stringValue = "正在读取…"
        service.loadVolcProfiles { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let response):
                self.volcProfilePopup.removeAllItems()
                for profile in response.profiles {
                    self.volcProfilePopup.addItem(withTitle: profile.name)
                }
                if let current = response.defaultProfile { self.volcProfilePopup.selectItem(withTitle: current) }
                self.volcStatus.stringValue = response.profiles.isEmpty ? "没有可用 Profile，请先登录" : "已读取 \(response.profiles.count) 个 Profile"
            case .failure(let error):
                self.volcStatus.stringValue = "读取失败：" + error.localizedDescription
            }
        }
    }

    @objc private func switchVolcProfile() {
        guard let name = volcProfilePopup.titleOfSelectedItem else { return }
        volcStatus.stringValue = "正在切换到 \(name)…"
        service.switchVolcProfile(name) { [weak self] result in
            switch result {
            case .success: self?.volcStatus.stringValue = "已切换到 \(name)"
            case .failure(let error): self?.volcStatus.stringValue = "切换失败：" + error.localizedDescription
            }
        }
    }

    @objc private func loginVolc() {
        volcStatus.stringValue = "正在启动火山 SSO，请在浏览器完成登录…"
        service.loginVolc { [weak self] result in
            switch result {
            case .success:
                self?.volcStatus.stringValue = "登录成功"
                self?.loadVolcProfiles()
            case .failure(let error):
                self?.volcStatus.stringValue = "登录失败：" + error.localizedDescription
            }
        }
    }

    private func reloadCodexStatus() {
        let authURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex/auth.json")
        codexStatus.stringValue = FileManager.default.fileExists(atPath: authURL.path)
            ? "当前状态：已检测到本机 Codex 登录，可直接切换并查询"
            : "当前状态：未检测到 Codex 登录，请先在 Codex 中完成登录"
    }

    private func reloadCredentialStatuses() {
        for (provider, status) in credentialStatuses {
            status.stringValue = service.hasCredential(for: provider)
                ? "当前状态：已保存凭证，可切换到该提供方查询"
                : "当前状态：尚未配置凭证"
        }
        qwenWorkspaceField.stringValue = service.qwenWorkspaceID ?? ""
    }

    @objc private func saveCredential(_ sender: NSButton) {
        guard let rawValue = sender.identifier?.rawValue,
              let provider = Provider(rawValue: rawValue),
              let field = credentialFields[provider] else { return }
        let workspace = provider == .qwen ? qwenWorkspaceField.stringValue : nil
        guard service.saveCredential(for: provider, apiKey: field.stringValue, workspaceID: workspace) else {
            showError(provider == .qwen
                ? "API Key 和 Workspace ID 均不能为空，或者钥匙串写入失败。"
                : "API Key 不能为空，或者钥匙串写入失败。")
            return
        }
        field.stringValue = ""
        reloadCredentialStatuses()
        reloadProviderButtons()
    }

    @objc private func deleteCredential(_ sender: NSButton) {
        guard let rawValue = sender.identifier?.rawValue,
              let provider = Provider(rawValue: rawValue) else { return }
        _ = service.deleteCredential(for: provider)
        reloadCredentialStatuses()
        reloadProviderButtons()
    }

    @objc private func openGeminiUsage() {
        guard let url = URL(string: "https://aistudio.google.com/") else { return }
        NSWorkspace.shared.open(url)
    }

    @objc private func confirmGeminiLogin() {
        service.setGeminiLoginConfirmed(true)
        reloadProviderButtons()
    }

    @objc private func clearGeminiLogin() {
        service.setGeminiLoginConfirmed(false)
        reloadProviderButtons()
    }

    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "设置未保存"
        alert.informativeText = message
        alert.runModal()
    }
}

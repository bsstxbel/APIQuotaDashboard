# API Quota Dashboard

[简体中文](README.md) · Current version: **2.2.0 (Build 28)**

API Quota Dashboard is a lightweight macOS menu bar app that brings balances, usage, and plan allowances from commonly used AI developer platforms into one place. It supports quick provider switching, scheduled refreshes, proxy settings, launch at login, and light/dark icons that can follow the system appearance.

> The current release is a Universal Binary for Apple silicon and Intel Macs and requires macOS 13.0 or later.

## Download and install

1. Download `APIQuotaDashboard-v2.2.0.zip` from [GitHub Releases](https://github.com/bsstxbel/APIQuotaDashboard/releases/latest).
2. Extract the archive and drag `API额度看板.app` into Applications.
3. Launch the app, then use its menu bar item to view quota information, switch providers, or open Settings.

The current package is ad-hoc signed and has not been notarized with an Apple Developer ID. If macOS blocks the first launch, Control-click the app in Finder, choose **Open**, and confirm **Open** again. Do not disable system-wide security protections.

## Supported providers

| Provider | Information shown | Credential or dependency |
| --- | --- | --- |
| DeepSeek | Available, topped-up, and granted balances | DeepSeek API key stored in macOS Keychain |
| Volcengine | Agent/Coding Plan allowance and free model quota | Installed and authenticated `arkcli` |
| Codex | Weekly and five-hour allowance | Local Codex sign-in |
| Claude | Organization API token usage for the last seven days | Organization Admin API key stored in macOS Keychain |
| Gemini | Official Google AI Studio Usage and Billing pages | Google AI Studio sign-in |
| Kimi | Available, cash, and voucher balances | Moonshot API key stored in macOS Keychain |
| Qwen | Per-model request and token limits | DashScope API key and Workspace ID |
| Doubao consumer plan | Five-hour and seven-day remaining percentages | Signed-in local Doubao app |
| Zhipu GLM | Remaining token/request packs, scope, expiry, and account balance | Chrome signed in to BigModel |
| MiniMax | Token Plan and remaining allowance | Token Plan key stored in macOS Keychain |
| OpenAI API | Organization costs for the last 30 days | Organization Admin API key stored in macOS Keychain |
| OpenRouter | Purchased credits, total usage, and remaining credits | Management key stored in macOS Keychain |
| SiliconFlow | Total, topped-up, and granted balances | SiliconFlow API key stored in macOS Keychain |

“Balance,” “usage,” and “subscription allowance” mean different things on different platforms. The app reports data through the currently available official APIs or local sign-in state and does not treat consumer subscriptions as developer API credit.

## How to use

1. Launch the app, click its quota text or icon in the macOS menu bar, and choose **Settings…**.
2. Configure the providers you want on the **Accounts** tab:
   - DeepSeek: enter an account name and API key, then choose **Save and Switch**.
   - Volcengine: install and sign in to `arkcli`, refresh the list, and select a profile.
   - Codex: sign in to Codex locally first; the app uses the existing local sign-in state.
   - Doubao: sign in to the local Doubao app and allow the macOS Keychain prompt on the first refresh.
   - Zhipu GLM: sign in to `open.bigmodel.cn` in Chrome and allow the Chrome Safe Storage prompt on the first refresh. A regular API key cannot read account resource packs.
   - Kimi, Qwen, MiniMax, Claude, OpenAI API, OpenRouter, and SiliconFlow: enter the required credentials and save them. Qwen also requires a Workspace ID.
   - Gemini: open Google AI Studio, sign in, and confirm that it should be added to the provider list.
3. On the **Providers** tab, select the items that should appear under **Switch Provider**, then save the selection.
4. Return to the menu bar menu to switch providers, refresh immediately, or choose an automatic refresh interval.

The **General** tab also controls launch at login, system or manual proxies, icon appearance, and custom refresh intervals. To reposition the menu bar item, hold Command (⌘) and drag it; macOS remembers the position.

## Highlights

- Shows the active balance, token amount, or remaining percentage directly in the menu bar.
- Switches quickly between providers and only offers providers that are configured or queryable.
- Supports 15-second, 30-second, one-minute, two-minute, five-minute, and custom refresh intervals.
- Supports system and manually configured proxies.
- Supports launch at login and light, dark, transparent, or system-matched icons.
- Offers value-only and provider-plus-value text modes, plus five-hour-only, total-only, or combined quota display when supported.
- Copies the current quota summary or redacted diagnostics from Settings and opens the provider's official console from the menu.
- Stores and switches between multiple DeepSeek accounts.
- Stores API keys in macOS Keychain rather than plain-text configuration files.

## Build from source

### Requirements

- macOS 13.0+
- Xcode 26 (required to compile the Icon Composer release asset)
- Swift 5.9 or later

### Build and test

```bash
swift test
swift build -c release
```

SwiftPM places the executable at `.build/release/APIQuotaDashboard`. The downloadable GitHub Release is packaged separately as a macOS app bundle.

`Scripts/release.sh` reproducibly builds the app bundle, Universal Binary, ad-hoc signature, ZIP, and SHA-256 checksum.

## Configuration and security

- `config.example.json` is a credential-free configuration example.
- `config.live.*.json`, `.build`, and local caches are ignored by Git.
- DeepSeek, Claude, Kimi, Qwen, MiniMax, OpenAI API, OpenRouter, and SiliconFlow keys are stored in macOS Keychain.
- Volcengine uses the local `arkcli` authentication state; Codex uses the existing local Codex credentials.
- Doubao and Zhipu GLM read only their local signed-in sessions and send them only to the official quota endpoints on `www.doubao.com` and `open.bigmodel.cn`; sessions are never stored in app configuration or logs.
- This repository does not contain real API keys, login tokens, or personal session archives.

You should still review network requests, credential permissions, and third-party terms before use. Provider API changes may temporarily break individual queries.

## What's new in 2.2.0

- Merges the previously unpublished 2.1.2 work: Doubao consumer-plan quota now refreshes in the background, with seven-day allowance above the five-hour allowance and its reset time.
- Doubao uses only the local signed-in session with the official quota endpoint; it does not read chats or save login credentials.
- Adds Zhipu GLM token/request resource packs, including remaining amount, scope, expiry, and account balance.
- Shows the combined effective GLM token packs in the menu bar while retaining model-specific and request-pack details in the expanded menu.
- Reads only the local Chrome session for `open.bigmodel.cn` and sends it only to the official Zhipu endpoints; regular API keys are not used for resource-pack queries.
- Automatically adds GLM to eligible upgraded configurations and updates console links and bilingual guidance.
- Expands the full test suite to 27 tests, including scoped GLM resource packs, account balances, and provider capabilities.

## Checksum

`APIQuotaDashboard-v2.2.0.zip`

```text
SHA-256: bc365c5df616a720758f24bc6e6e9e83692422701d50429a467df95039b890d9
```

## Disclaimer

This project is not affiliated with or endorsed by DeepSeek, Volcengine, Doubao, Zhipu AI, OpenAI, Anthropic, Google, Moonshot AI, Alibaba Cloud, or MiniMax. All product names and trademarks belong to their respective owners.

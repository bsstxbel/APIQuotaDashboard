# API Quota Dashboard

[简体中文](README.md) · Current version: **1.5.12 (Build 19)**

API Quota Dashboard is a lightweight macOS menu bar app that brings balances, usage, and plan allowances from commonly used AI developer platforms into one place. It supports quick provider switching, scheduled refreshes, proxy settings, launch at login, and light/dark icons that can follow the system appearance.

> The current release is built for Apple Silicon Macs and requires macOS 13.0 or later.

## Download and install

1. Download `APIQuotaDashboard-v1.5.12.zip` from [GitHub Releases](https://github.com/bsstxbel/APIQuotaDashboard/releases/latest).
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
| MiniMax | Token Plan and remaining allowance | Token Plan key stored in macOS Keychain |

“Balance,” “usage,” and “subscription allowance” mean different things on different platforms. The app reports data through the currently available official APIs or local sign-in state and does not treat consumer subscriptions as developer API credit.

## Highlights

- Shows the active balance, token amount, or remaining percentage directly in the menu bar.
- Switches quickly between providers and only offers providers that are configured or queryable.
- Supports 15-second, 30-second, one-minute, two-minute, five-minute, and custom refresh intervals.
- Supports system and manually configured proxies.
- Supports launch at login and light, dark, transparent, or system-matched icons.
- Stores and switches between multiple DeepSeek accounts.
- Stores API keys in macOS Keychain rather than plain-text configuration files.

## Build from source

### Requirements

- macOS 13.0+
- Xcode 15 or a compatible Swift 5.9 toolchain
- Apple Silicon Mac (the current packaged release is `arm64`)

### Build and test

```bash
swift test
swift build -c release
```

SwiftPM places the executable at `.build/release/APIQuotaDashboard`. The downloadable GitHub Release is packaged separately as a macOS app bundle.

## Configuration and security

- `config.example.json` is a credential-free configuration example.
- `config.live.*.json`, `.build`, and local caches are ignored by Git.
- DeepSeek, Claude, Kimi, Qwen, and MiniMax keys are stored in macOS Keychain.
- Volcengine uses the local `arkcli` authentication state; Codex uses the existing local Codex credentials.
- This repository does not contain real API keys, login tokens, or personal session archives.

You should still review network requests, credential permissions, and third-party terms before use. Provider API changes may temporarily break individual queries.

## What's new in 1.5.12

- Fixed account setup entries disappearing before a provider was signed in or configured.
- Kept setup or sign-in entries for all eight supported providers visible on the Accounts page.
- Providers that require extra credentials only appear in the display selector after setup.
- Added or refined query support and official entry points for Kimi, Qwen, MiniMax, Claude, and Gemini.
- Removing credentials or clearing the Gemini sign-in marker now removes the corresponding display option.

## Checksum

`APIQuotaDashboard-v1.5.12.zip`

```text
SHA-256: 063ea032a33917f7eac21df315aad7538e8eab2aac693bb92a01a56573271b43
```

## Disclaimer

This project is not affiliated with or endorsed by DeepSeek, Volcengine, OpenAI, Anthropic, Google, Moonshot AI, Alibaba Cloud, or MiniMax. All product names and trademarks belong to their respective owners.

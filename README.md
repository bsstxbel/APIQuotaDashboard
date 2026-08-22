# API 额度看板

[English](README_EN.md) · 当前版本：**1.5.12（Build 19）**

API 额度看板是一款轻量的 macOS 菜单栏应用，用于集中查看常用 AI 开发平台的余额、用量或套餐余量。它支持快速切换提供方、定时刷新、系统代理、登录启动，以及跟随系统的浅色/深色图标。

> 当前发布包适用于 Apple 芯片 Mac，要求 macOS 13.0 或更高版本。

## 下载与安装

1. 从 [GitHub Releases](https://github.com/bsstxbel/APIQuotaDashboard/releases/latest) 下载 `APIQuotaDashboard-v1.5.12.zip`。
2. 解压后，将 `API额度看板.app` 拖入“应用程序”文件夹。
3. 启动应用，从菜单栏查看额度、切换提供方或打开设置。

当前安装包使用临时（ad-hoc）签名，尚未经过 Apple Developer ID 公证。如果 macOS 首次启动时拦截，请在 Finder 中右键应用，选择“打开”，然后再次确认“打开”。不要关闭系统级安全保护。

## 支持的提供方

| 提供方 | 显示内容 | 凭证或依赖 |
| --- | --- | --- |
| DeepSeek | 可用余额、充值余额、赠送余额 | DeepSeek API Key，保存于 macOS 钥匙串 |
| 火山引擎 | Agent/Coding Plan 订阅余量、免费模型额度 | 已安装并登录 `arkcli` |
| Codex | 周额度与 5 小时额度 | 本机 Codex 登录状态 |
| Claude | 组织最近 7 天 API Token 用量 | 组织 Admin API Key，保存于 macOS 钥匙串 |
| Gemini | Google AI Studio Usage / Billing 官方入口 | Google AI Studio 登录 |
| Kimi | 可用余额、现金余额、代金券余额 | Moonshot API Key，保存于 macOS 钥匙串 |
| 通义千问 | 各模型请求与 Token 限额 | DashScope API Key 与 Workspace ID |
| MiniMax | Token Plan 与套餐剩余 | Token Plan Key，保存于 macOS 钥匙串 |

不同平台的“余额”“用量”和“订阅额度”口径并不相同。本应用按各平台当前可用的官方接口或本机登录状态展示信息，不会把个人会员额度与开放平台 API 额度混为一谈。

## 使用方法

1. 启动应用后，点击 macOS 菜单栏中的额度文字或图标，再选择“设置…”。
2. 在“账号”页配置需要使用的提供方：
   - DeepSeek：填写账号名称和 API Key，然后点击“保存并切换”。
   - 火山引擎：先安装并登录 `arkcli`，再刷新列表并选择 Profile。
   - Codex：先在本机完成 Codex 登录，应用会直接使用已有登录状态。
   - Kimi、通义千问、MiniMax、Claude：填写对应凭证并点击“保存凭证”；通义千问还需要 Workspace ID。
   - Gemini：点击“打开 Google AI Studio”，登录后选择“我已登录，加入显示提供方”。
3. 在“提供方”页勾选需要出现在“切换提供方”菜单中的项目，然后点击“保存显示项目”。
4. 回到菜单栏菜单，通过“切换提供方”查看不同平台，使用“立即刷新”或“自动刷新时间”控制更新频率。

“通用”页还可以设置登录启动、系统或手动代理、图标外观和自定义刷新间隔。若要调整菜单栏位置，请按住 Command（⌘）拖动额度文字；位置由 macOS 记忆。

## 主要功能

- 菜单栏直接显示当前余额、Token 数或剩余百分比。
- 在多个提供方之间快速切换，并仅显示已配置或可查询的项目。
- 支持 15 秒、30 秒、1 分钟、2 分钟、5 分钟及自定义刷新间隔。
- 支持系统代理或手动代理配置。
- 支持登录时启动，以及浅色、深色、透明或跟随系统的图标。
- DeepSeek 支持多账号保存与切换。
- API Key 写入 macOS 钥匙串，不在普通配置文件中保存明文。

## 从源码构建

### 环境要求

- macOS 13.0+
- Xcode 15 或兼容的 Swift 5.9 工具链
- Apple 芯片 Mac（当前发布包为 `arm64`）

### 构建与测试

```bash
swift test
swift build -c release
```

SwiftPM 生成的可执行文件位于 `.build/release/APIQuotaDashboard`。GitHub Release 中提供的是已经组装为 macOS App Bundle 的安装包。

## 配置与安全

- `config.example.json` 是不含密钥的配置示例。
- `config.live.*.json`、`.build` 和本地缓存均已被 Git 忽略。
- DeepSeek、Claude、Kimi、通义千问和 MiniMax 的密钥通过 macOS 钥匙串保存。
- 火山引擎依赖本机 `arkcli` 的登录状态；Codex 读取本机已有的登录凭证。
- 本仓库不包含真实 API Key、登录令牌或个人会话记录。

公开发布前仍建议自行审阅网络请求、凭证权限和第三方平台条款。第三方接口发生变化时，查询结果可能暂时不可用。

## 1.5.12 更新内容

- 修正未登录或尚未填写密钥时配置入口被隐藏的问题。
- 账号页固定保留八个支持提供方的配置或登录入口。
- 需要额外凭证的提供方，仅在完成配置后出现在显示选择中。
- 新增或完善 Kimi、通义千问、MiniMax、Claude 和 Gemini 的查询或官方入口。
- 删除凭证或取消 Gemini 登录标记时，同步移除对应显示项目。

## 校验值

`APIQuotaDashboard-v1.5.12.zip`

```text
SHA-256: 063ea032a33917f7eac21df315aad7538e8eab2aac693bb92a01a56573271b43
```

## 免责声明

本项目与 DeepSeek、火山引擎、OpenAI、Anthropic、Google、Moonshot AI、阿里云或 MiniMax 无隶属或背书关系。所有产品名与商标归其各自权利人所有。

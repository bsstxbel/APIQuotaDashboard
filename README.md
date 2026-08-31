# API 额度看板

[English](README_EN.md) · 当前版本：**2.2.0（Build 28）**

API 额度看板是一款轻量的 macOS 菜单栏应用，用于集中查看常用 AI 开发平台的余额、用量或套餐余量。它支持快速切换提供方、定时刷新、系统代理、登录启动，以及跟随系统的浅色/深色图标。

> 当前发布包同时包含 Apple 芯片与 Intel 架构，要求 macOS 13.0 或更高版本。

## 下载与安装

1. 从 [GitHub Releases](https://github.com/bsstxbel/APIQuotaDashboard/releases/latest) 下载 `APIQuotaDashboard-v2.2.0.zip`。
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
| 豆包个人订阅 | 5 小时与近 7 天剩余百分比 | 本机已登录豆包客户端 |
| 智谱 GLM | Token/次数资源包剩余、适用范围、到期时间与账户余额 | Chrome 已登录智谱 BigModel |
| MiniMax | Token Plan 与套餐剩余 | Token Plan Key，保存于 macOS 钥匙串 |
| OpenAI API | 最近 30 天组织成本 | 组织 Admin API Key，保存于 macOS 钥匙串 |
| OpenRouter | 已购额度、累计用量、剩余额度 | Management Key，保存于 macOS 钥匙串 |
| 硅基流动 | 总余额、充值余额、赠送余额 | 硅基流动 API Key，保存于 macOS 钥匙串 |

不同平台的“余额”“用量”和“订阅额度”口径并不相同。本应用按各平台当前可用的官方接口或本机登录状态展示信息，不会把个人会员额度与开放平台 API 额度混为一谈。

## 使用方法

1. 启动应用后，点击 macOS 菜单栏中的额度文字或图标，再选择“设置…”。
2. 在“账号”页配置需要使用的提供方：
   - DeepSeek：填写账号名称和 API Key，然后点击“保存并切换”。
   - 火山引擎：先安装并登录 `arkcli`，再刷新列表并选择 Profile。
   - Codex：先在本机完成 Codex 登录，应用会直接使用已有登录状态。
   - 豆包：先登录本机豆包客户端；首次刷新时按 macOS 提示允许读取本机登录会话。
   - 智谱 GLM：先在 Chrome 登录 `open.bigmodel.cn`；首次刷新时按 macOS 提示允许读取 Chrome Safe Storage。普通 API Key 不能查询账户资源包。
   - Kimi、通义千问、MiniMax、Claude、OpenAI API、OpenRouter、硅基流动：填写对应凭证并点击“保存凭证”；通义千问还需要 Workspace ID。
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
- 支持“仅额度”或“提供方 + 额度”两种文字模式；有 5 小时限额时可只显示 5 小时、只显示总额或同时显示。
- 可在设置中复制当前额度摘要或不含密钥的诊断信息，并可从展开菜单打开提供方官方控制台。
- DeepSeek 支持多账号保存与切换。
- API Key 写入 macOS 钥匙串，不在普通配置文件中保存明文。

## 从源码构建

### 环境要求

- macOS 13.0+
- Xcode 26（发布包需要编译 Icon Composer 图标）
- Swift 5.9 或更高版本

### 构建与测试

```bash
swift test
swift build -c release
```

SwiftPM 生成的可执行文件位于 `.build/release/APIQuotaDashboard`。GitHub Release 中提供的是已经组装为 macOS App Bundle 的安装包。

完整的 App Bundle、通用二进制、ad-hoc 签名、ZIP 与 SHA-256 校验可通过 `Scripts/release.sh` 重复生成。

## 配置与安全

- `config.example.json` 是不含密钥的配置示例。
- `config.live.*.json`、`.build` 和本地缓存均已被 Git 忽略。
- DeepSeek、Claude、Kimi、通义千问、MiniMax、OpenAI API、OpenRouter 和硅基流动的密钥通过 macOS 钥匙串保存。
- 火山引擎依赖本机 `arkcli` 的登录状态；Codex 读取本机已有的登录凭证。
- 豆包和智谱 GLM 仅在本机读取对应登录会话，并分别只向 `www.doubao.com` 与 `open.bigmodel.cn` 的官方额度接口发送请求；会话不会写入配置或日志。
- 本仓库不包含真实 API Key、登录令牌或个人会话记录。

公开发布前仍建议自行审阅网络请求、凭证权限和第三方平台条款。第三方接口发生变化时，查询结果可能暂时不可用。

## 2.2.0 更新内容

- 合并此前未公开发布的 2.1.2 更新：豆包个人订阅改为后台自动查询，上方显示近 7 天、下方显示 5 小时剩余及重置时间。
- 豆包仅使用本机登录会话访问官方额度接口，不读取聊天记录，也不保存登录凭证。
- 新增智谱 GLM：读取 Token/次数资源包的总量、剩余量、适用范围、到期时间和账户余额。
- GLM 菜单栏显示有效 Token 资源包合计，展开菜单保留各模型专属包和次数包的分项信息。
- GLM 仅从本机 Chrome 读取 `open.bigmodel.cn` 登录会话，并只向智谱官方接口发送；普通 API Key 不用于账户资源包查询。
- 升级现有配置时自动加入可查询的 GLM 提供方，并更新官方控制台入口和中英文使用说明。
- 完整测试增至 27 项，覆盖 GLM 分范围资源包、账户余额和提供方能力。

## 校验值

`APIQuotaDashboard-v2.2.0.zip`

```text
SHA-256: bc365c5df616a720758f24bc6e6e9e83692422701d50429a467df95039b890d9
```

## 免责声明

本项目与 DeepSeek、火山引擎、豆包、智谱 AI、OpenAI、Anthropic、Google、Moonshot AI、阿里云或 MiniMax 无隶属或背书关系。所有产品名与商标归其各自权利人所有。

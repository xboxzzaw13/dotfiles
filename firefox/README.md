# Firefox

Linux 上的 Firefox 插件配置，独立于 NixOS，可用于当前 Arch Linux 和后续迁移。

## 使用

先安装 Firefox、Python 3，以及 `settings.json` 中列出的扩展和暴力猴。首次启动 Firefox 后关闭所有使用目标配置的窗口。

在 dotfiles 根目录运行，临时目录需要尚不存在：

```bash
python3 firefox/configure.py --stage /tmp/firefox-setup
python3 firefox/configure.py --commit /tmp/firefox-setup
```

默认读取 `~/.config/mozilla/firefox/profiles.ini` 或 `~/.mozilla/firefox/profiles.ini` 中的安装默认配置。可以用 `--profile /path/to/profile` 指定其他配置。

准备阶段只使用临时 Firefox。LinkSwift 通过暴力猴自身的安装接口导入，脚本依赖下载完整后才继续。选项通过 Firefox 自己的存储接口写入副本，并在重启后读回验证。应用前会校验原数据是否发生变化，并用 Firefox 的配置锁阻止同时打开目标配置。

应用时仅复制目标扩展的存储，不复制浏览器的 Cookie、登录数据库、会话文件、`prefs.js` 或 `user.js`。原插件中没有托管的设置和数据会保留。备份位置会打印在终端，默认在：

```text
~/.local/state/dotfiles/firefox/backups/<时间戳>/
```

关闭 Firefox 后恢复：

```bash
python3 firefox/configure.py --restore /path/to/backup
```

临时目录包含插件的本机数据，按私有权限创建，不应上传或加入 Git。备份同样只保存在本机。

## 配置内容

| 扩展 | 配置 |
| --- | --- |
| Vimium C | 深色界面、平滑滚动；保留默认键位；增加 `Alt+J/K` 切换标签；视频播放页放行播放器常用键位 |
| Search by Image | 右键搜图片、工具栏截图搜图；只启用 Google Lens、Yandex、Bing、百度；关闭全部引擎同时搜索 |
| Dark Reader | Catppuccin Mocha 背景与文字色；识别已有深色主题；排除已有主题的 YouTube 和 Bilibili |
| SponsorBlock | 自动跳过赞助、自我推广、求赞；片头、片尾、预告保留手动跳过按钮 |
| Sidebery | 保留树状标签和现有面板；每 30 分钟保存快照，最多 48 份，排除隐私窗口 |
| Enhancer for YouTube | 默认 1080p；关闭自动续播、暂停其他播放中的视频；倍速步长 0.25 |
| 沉浸式翻译 | 中文界面、简体中文双语对照；保留现有账号、翻译服务和站点规则 |
| 暴力猴 | 安装 LinkSwift 稳定版，启用脚本更新，缓存脚本所需依赖 |

uBlock Origin 当前已有默认列表及中文过滤列表，BewlyCat 已启用深色主题和链接清理，因此保留它们的现有设置。浏览器主题继续使用 Catppuccin Mocha - Mauve，Pywalfox 本轮未调整。

## 键盘入门

| 按键 | 操作 |
| --- | --- |
| `f` / `F` | 显示链接提示，在当前 / 新标签打开 |
| `j` / `k` | 上下滚动；在配置的视频播放页交给播放器 |
| `o` / `O` | 搜索、打开网址、书签或历史记录 |
| `Alt+J` / `Alt+K` | 上一个 / 下一个标签 |
| `x` / `X` | 关闭 / 恢复标签 |
| `yy` | 复制当前网址 |
| `i` / `Esc` | 暂时将按键交给网页 / 退出输入模式 |
| `?` | Vimium C 帮助 |
| `Alt+A` | 沉浸式翻译：切换当前网页翻译 |

在 Vimium C 搜索框中输入 `gh firefox` 搜索 GitHub、`bili firefox` 搜索 B 站、`yt firefox` 搜索 YouTube，另有 `g`、`bing`、`bd`。

## LinkSwift

固定的上游脚本位于 `userscripts/linkswift.user.js`，来源、版本及 SHA-256 记录在 `userscripts/linkswift.json`，本次采用官方稳定版 1.1.3。保留上游脚本及许可声明。

安装后刷新百度网盘页面，勾选文件，使用“下载助手”。首次使用百度 API 下载时，可能需要按百度页面提示完成授权。脚本已设置 Linux Shell 命令格式，可以复制 cURL 下载命令；下载速度仍受账号权益和服务端限制影响。

aria2 是可选的本机下载器，当前脚本不会自动安装它。如需接入，创建仅本机保存的 `~/.config/aria2/linkswift-rpc.json`，格式对应 LinkSwift 的 RPC 配置（`domain`、`port`、`path`、`token`、`dir`、`default`），然后重新准备并应用。程序只在运行时读取它，RPC 密钥不写入仓库。

扩展升级后，建议先运行准备阶段验证；部分配置使用扩展和 Firefox 的内部接口，版本变更时可能需要适配。

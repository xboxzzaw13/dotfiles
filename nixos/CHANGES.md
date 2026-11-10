# 改动与验证记录

审计日期：2026-11-10。结论是**已完成仓库重构与静态检查，尚未完成 NixOS 构建和硬件验收**。当前执行环境没有 Nix，没有访问目标笔记本；没有安装 Nix、修改本机系统、执行 sudo、分区、引导安装、git commit/push 或破坏性 Git 操作。

## 原始状态与保留内容

开始时 `git status --short` 与 diff 为空。仓库的 NixOS 文件只有 flake、lock、configuration、home 和未被导入的 Hyprland Lua；没有另外一套 Shell、终端或编辑器模块可迁移。Firefox 子目录属于另一套工作，不作修改。

保留 `Ac0-Nomad` 名称、用户名、已有公开 Git 身份、26.05 system/home stateVersion、Bash/Starship、Kitty/Neovim/Firefox/Yazi/btop、中文字体和 fcitx5、PipeWire、greetd/tuigreet、Windows 本地 RTC、常用 Vim/方向键工作流。现有 locale 保持 en_US.UTF-8，时区从 Los Angeles 调为目标所在地 Asia/Shanghai，可由 Host 覆盖。

## 主要变更

- `configuration.nix` 与 `home.nix` 变成可复用基线；Host 明确导入桌面、笔记本、NVIDIA 和本地容器模块；没有引入新 flake inputs 或泛化 option 框架。
- Host 接管引导、默认 LTS 内核、AMD 微码、PRIME Bus ID、NVIDIA RTD3、设备 DRM 别名、内屏规则与各自 stateVersion。硬件文件缺失触发明确 assertion，不编造分区。
- HM 随系统 generation 管理主要软件、Lua、辅助脚本和用户服务。NixOS 管理 compositor、portal、PAM；UWSM 是唯一图形会话管理者。
- 完整键位扩展为 91 个实际绑定；Super+L 与 `Super+l` 原本冲突，锁屏改为 Ctrl+Alt+L；保留方向/Vim 双键位、窗口操作、1–10 工作区、暂存区，补齐麦克风与媒体键。删除依赖 X11 窗口列表的 rofi window 切换，用 compositor cycle 代替。
- 截图和剪贴板改成带明确依赖的 `writeShellApplication`。取消选择或捕获/解码失败不会覆盖现有剪贴板；截图锁屏期间禁用，静音键不连续重复切换。
- Waybar 使用简单内建模块、mako 使用 D-Bus 激活；去除没有壁纸配置的 hyprpaper、Lua 中的重复后台启动和 primary clipboard watcher。未添加主题系统。
- Git 使用新 HM `settings` API，凭据从明文 `store` 改为内存 `cache`；修复 `rg = ripgrep` 不存在的命令别名。加入 delta、zoxide、tmux、direnv/nix-direnv。原先同时安装 htop/btop，统一保留 btop；系统 TTY 仍独立保留 vim/git/网络工具。
- 移除公开默认口令、无必要的 `input`/`video` 组、默认开放的 sshd。保留密码 sudo、防火墙、polkit；SSH agent 只供出站开发使用，代理转发默认关闭。
- 电源策略由 TLP 1.10.2 按电源切换，PPD 关闭；不强制 CPU 参数/充电阈值，不改变未测量的 swap/休眠布局。
- 本地容器采用 rootless Podman，不安装第二个引擎；上游模块默认启动 root API socket，已明确屏蔽 root service/socket，并取消用户 socket 自动启动。GPU 容器与完整 CUDA/ML/RL 不预装。
- GC 保留窗口从 14 天延到 30 天；缓存收敛到 USTC 与明确的官方 fallback，继续验证官方签名。镜像不等于输入源码镜像。

## 输入与版本

| 组件 | 本次源码依据 | 锁状态 |
| --- | --- | --- |
| nixpkgs | `09063bd1f2b36fd9fd793c36dfade7bd40a93dfc` | 原始锁完全保留 |
| Home Manager | `82ce401aa350502897c3f2e85f384d61cd3b0b6d`，上游 patch 标明 2026-10-16 | 原锁完全没有 HM；flake 现在固定此已审计提交，等待 Nix 生成条目 |
| Hyprland | 0.56.2 | nixpkgs 包，无单独 input |
| Linux | 默认 LTS 6.18.57；原 `linuxPackages_latest` 在同一 nixpkgs 对应 7.2.11 | 不升级 nixpkgs，改用已有默认内核系列 |
| NVIDIA | stable → production 595.104.02 | 与选择的 kernelPackages 配套 |
| UWSM / hypridle / TLP | 0.27.0 / 0.1.8 / 1.10.2 | 来自同一个 nixpkgs |

原 nixpkgs 输入是移动的 USTC `nixos-unstable/nixexprs.tar.xz`，锁的 `original` 却是 GitHub nixos-unstable。恢复 canonical GitHub 输入是为了保留已有 revision，而不是让 Nix 隐式重新锁到镜像当天内容。Home Manager 此前只有未锁定的 master URL，没有可保留的旧 HM revision；此次选择获取并审计的具体提交，没有编造它的 NAR hash。

`flake.lock` 与 HEAD 字节完全相同，文件 SHA256：`4ff4085595e2533f1e69a0ebf1ee1cb4eb8bab38c57b2e407c96ec85fcfad0ee`（这是文件校验，不是 NAR hash）。实际锁修复与固定提交 codeload 备用流程见 [DEPLOYMENT.md](DEPLOYMENT.md)。

## 关键源码依据

这里的“源码已确认”指读取了定义、相关默认值/实现和 assertions，不代表模块已经通过 Nix 求值。

| 判断 | 依据与边界 |
| --- | --- |
| Hyprland 0.56.2 和 Lua | [锁定包](https://github.com/NixOS/nixpkgs/blob/09063bd1f2b36fd9fd793c36dfade7bd40a93dfc/pkgs/by-name/hy/hyprland/package.nix)、[0.56.2 示例](https://github.com/hyprwm/Hyprland/blob/v0.56.2/example/hyprland.lua)、[dispatcher 实现](https://github.com/hyprwm/Hyprland/blob/v0.56.2/src/config/lua/bindings/LuaBindingsDispatchers.cpp)。检查 focus、move/follow、swap、resize、fullscreen、float、cycle_next、special、DPMS 与 bind 选项；使用完整方向名。 |
| HM Lua 真实部署 | [HM 模块](https://github.com/nix-community/home-manager/blob/82ce401aa350502897c3f2e85f384d61cd3b0b6d/modules/services/window-managers/hyprland/default.nix) 和同目录 `lib.nix`：`configType=lua`、`extraConfig`、`extraLuaFiles`、nullable package/portal，加载目录与执行顺序已读。 |
| 系统与会话边界 | [NixOS Hyprland](https://github.com/NixOS/nixpkgs/blob/09063bd1f2b36fd9fd793c36dfade7bd40a93dfc/nixos/modules/programs/wayland/hyprland.nix)、同目录 `uwsm.nix`/`wayland-session.nix`；系统自动加入 Hyprland 与 GTK portals。[UWSM 0.27.0](https://github.com/Vladimir-csp/uwsm/tree/v0.27.0) 的环境加载、autostart 和 session 生命周期已读。Hyprland 自行导入 WAYLAND_DISPLAY，UWSM 无需再加 finalize 启动进程。 |
| GPU 顺序 | [Aquamarine 说明](https://github.com/hyprwm/aquamarine/blob/main/docs/env.md) 定义冒号分隔的 `AQ_DRM_DEVICES`，首项是主 GPU；PCI by-path 自身含冒号，因此用 Host udev 别名。实际设备存在性/渲染器需要硬件验证。 |
| NVIDIA 参数 | [锁定 NixOS 模块](https://github.com/NixOS/nixpkgs/blob/09063bd1f2b36fd9fd793c36dfade7bd40a93dfc/nixos/modules/hardware/video/nvidia.nix)：`prime.amdgpuBusId`，offload/finegrained 的依赖与 sync 冲突、`nvidia-offload`、RTD3 udev 规则。595+open 默认 kernelSuspendNotifier；powerManagement 启用显存保存。本次未复制旧版 suspend hook 或强制关闭 GSP。 |
| 驱动/内核版本 | [驱动集合](https://github.com/NixOS/nixpkgs/blob/09063bd1f2b36fd9fd793c36dfade7bd40a93dfc/pkgs/os-specific/linux/nvidia-x11/default.nix)、[内核别名](https://github.com/NixOS/nixpkgs/blob/09063bd1f2b36fd9fd793c36dfade7bd40a93dfc/pkgs/top-level/linux-kernels.nix)、`pkgs/os-specific/linux/kernel/kernels-org.json`。构建兼容性仍需实际 build。 |
| 16ACHG6 音频 | [6.18.57 alc269.c](https://kernel.googlesource.com/pub/scm/linux/kernel/git/stable/linux/+/refs/tags/v6.18.57/sound/hda/codecs/realtek/alc269.c) 含 `17aa:3847` → `ALC287_FIXUP_LEGION_16ACHG6` → `CLSA0100` 双功放绑定；[cs35l41_hda_property.c](https://kernel.googlesource.com/pub/scm/linux/kernel/git/stable/linux/+/refs/tags/v6.18.57/sound/hda/codecs/side-codecs/cs35l41_hda_property.c) 含 CLSA0100 的 missing-DSD 处理与外置 boost 类型。16ITHG6 是 CLSA0101，不能混用。未验证实际 kernel .config、设备固件加载和声音。 |
| 电源与合盖 | [TLP 模块](https://github.com/NixOS/nixpkgs/blob/09063bd1f2b36fd9fd793c36dfade7bd40a93dfc/nixos/modules/services/hardware/tlp.nix) 的类型、生成器、服务与冲突已读；[TLP 1.10.2 defaults](https://github.com/linrunner/TLP/blob/1.10.2/defaults.conf) 的 AC/BAT profile/EPP、runtime PM 默认已核对。覆盖 runtime PM 为留空，保留 GPU 驱动自己的规则；[处理器配置](https://linrunner.de/tlp/settings/processor.html) 说明 EPP 依赖对应驱动/硬件。`services.logind.settings.Login` 已按锁定模块核对。 |
| 锁屏与挂起 | [HM hypridle](https://github.com/nix-community/home-manager/blob/82ce401aa350502897c3f2e85f384d61cd3b0b6d/modules/services/hypridle.nix)、[hypridle 0.1.8](https://github.com/hyprwm/hypridle/blob/v0.1.8/src/core/Hypridle.cpp)：支持 inhibit_sleep=3 与 lock notification；NixOS 增加 PAM。UWSM 不把 session ID 放进公共用户环境，因此后台使用 `loginctl lock-sessions`。实际锁定时序需验收。 |
| 中文输入 | [fcitx5 NixOS 模块](https://github.com/NixOS/nixpkgs/blob/09063bd1f2b36fd9fd793c36dfade7bd40a93dfc/nixos/modules/i18n/input-method/fcitx5.nix) 与 `pkgs/tools/inputmethods/fcitx5/with-addons.nix`：Wayland 模式不全局设置 GTK/Qt IM_MODULE，包装 addons/GTK/Qt 插件、autostart 与 config tool。应用级协议兼容待测。 |
| Podman 的默认副作用 | [Podman 模块](https://github.com/NixOS/nixpkgs/blob/09063bd1f2b36fd9fd793c36dfade7bd40a93dfc/nixos/modules/virtualisation/podman/default.nix) 默认把系统/用户 socket 加入 sockets.target；已覆写。`users-groups.nix` 默认给普通用户分配 subordinate UID/GID。toolkit 的 CDI 模块只作为未来接口说明，当前不启用。 |
| Shell/工具 API | 同一 HM 的 `git.nix`/`ssh.nix`/`delta.nix`/`direnv.nix`/`ssh-agent.nix` 已读，采用新 `settings` API；包定义已核对（包括生成的 `maple-mono.Normal-CN`）。brightnessctl 可通过 logind 调亮度，锁定 nixpkgs 的 rename 说明已移除旧 udev 模块，不需要补 `input` 组。 |
| 缓存与源码 | [USTC 说明](https://mirrors.ustc.edu.cn/help/nix-channels.html) 明确 channel 与动态 binary cache 的用途及 narinfo/NAR 不同步情况；[Nix flake 引用](https://nix.dev/manual/nix/2.24/command-ref/new-cli/nix3-flake.html) 支持显式 `path:` 与 `tarball+https:`。必须由 Nix 生成锁并校验 NAR，不以 HTTP 代替完整性验证。 |

## 本次检查结果

- **静态语法通过**：11 个 `.nix` 文件由本机已有 Tree-sitter runtime 加临时下载的 `tree-sitter-nix` grammar 解析，无 ERROR 节点。grammar revision `eabf96807ea4ab6d6c7f09b671a88cd483542840`，来源为锁定 nixpkgs 自己的 grammar 列表。这不是 Nix 求值，不能发现所有未知选项、类型或包合并错误。
- **Lua 语法通过**：共享 Lua、Host Lua 和键位检查器分别 `luac -p`；91 个实际展开绑定唯一、文档与配置一致；注入旧 `Super+L` 大小写冲突的反例被拒绝。模拟 dispatcher 不替代实际 compositor。
- **ShellCheck 通过**：两个脚本按 Bash 检查；临时隔离 stub 验证截图取消/捕获失败/成功、剪贴板取消/解码失败/成功，共 6 个场景。未对真实 Wayland 剪贴板进行操作。
- **依赖路径审查**：本地路径存在，唯一预期缺失的是 Host 硬件文件；全部导入显式，无循环。桌面快捷键命令已对应到 HM/NixOS 包（uwsm、Hyprland、systemd、blueman、NetworkManager、WirePlumber、playerctl、brightnessctl 或打包脚本）。包存在不等于已成功构建。
- **锁诊断符合预期**：`python3 scripts/check-network.py --offline` 退出 2，准确报告缺 Home Manager；原 nixpkgs `original` 与修复后的 flake 一致，lock 文件未变。
- **执行端联网检查**：两个 GitHub archive API HTTP 200；两个固定提交 codeload 源码成功下载；USTC/官方 `nix-cache-info` HTTP 206（Range 探测），内容含 `/nix/store`。提交元数据 API 曾 403、部分 raw URL 曾 429；没有把一次成功当长期可靠性，也没有测目标网络。
- **变更范围检查**：`git diff --check` 无空白错误；改动集中在 `nixos/` 与根 README 链接；Firefox 未变。没有新增私钥、口令或 Token；初始口令已移除。新增文件当前未暂存，部署方法明确避免 Git 未跟踪文件遗漏。

临时审计源码、语法 parser 和 stub 测试在执行端 `/tmp/nixos-refactor-audit/`，未将上游整份源码或测试下载包复制进仓库。仓库内保留的检查命令（从 `nixos/`）：

```bash
lua scripts/check-keybindings.lua
luac -p config/wm/hypr/hyprland.lua
luac -p hosts/Ac0-Nomad/hyprland.lua
shellcheck -s bash scripts/screenshot.sh scripts/clipboard.sh
python3 scripts/check-network.py --offline
```

## 验证层级与剩余事项

| 层级 | 结论 |
| --- | --- |
| 源码已确认 | 上表中的版本、选项定义、默认值、实现与约束 |
| 静态分析推断 | 模块边界、安装依赖覆盖、服务唯一所有权、Lua 绑定与文档一致性 |
| 需要真实 Nix 求值 | 补齐 lock、确认 HM/nixpkgs 组合、assertions、所有 option 类型/合并、生成文件/单位 |
| 需要真实构建 | 整个系统闭包、内核/NVIDIA、包可用缓存、首次激活与回滚 |
| 需要目标硬件验证 | Hybrid 模式、PCI/DRM/内屏名、AMD renderer、RTD3、外屏、音频、fcitx 应用兼容、锁屏/睡眠、CPPC/电源策略、充电与电池数据、ESP/Windows、容器 rootless |
| 已知阻塞 | HM lock 缺失、硬件配置缺失、本执行端无 Nix、目标机器不可访问 |

不声称整体达到完整验收；按 [DEPLOYMENT.md](DEPLOYMENT.md) 逐项记录目标机结果之后再改变此状态。

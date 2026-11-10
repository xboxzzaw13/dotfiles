# 部署、验收与恢复

本文命令的工作目录均为仓库的 **`nixos/`**，Host 为 **`Ac0-Nomad`**。本机未安装 Nix，以下 Nix 命令是待在目标 NixOS / Live USB 上执行的步骤，并非已通过的测试。

## 当前阻塞

- `hosts/Ac0-Nomad/hardware-configuration.nix` 尚未生成。Host 有明确 assertion；不能据此构建一个可安装系统。
- `flake.lock` 原文件只含 nixpkgs，缺少 Home Manager。此次未手改锁；必须让 Nix 补齐后再构建。
- 目标大陆网络、BIOS Hybrid 模式、磁盘/ESP、实际 RAM、内屏连接器和所有硬件行为尚未验收。

所有示例使用 `path:$PWD`，明确把本地新增/被忽略的文件纳入 flake 快照。默认 Git flake 会忽略未跟踪文件，尤其根 `.gitignore` 原本就忽略所有 `hardware-configuration.nix`。如果以后改用 `--flake .#Ac0-Nomad`，必须先检查 `git ls-files nixos` 并显式跟踪所需新文件；硬件文件可在本机用 `git add -f` 纳入，发布前审阅 UUID 等设备信息。当前 agent 未进行 staging、commit 或 push。

## 1. 首次安装前

备份 Windows 数据、恢复密钥和现有 EFI 文件，准备可启动的 NixOS UEFI Live USB、可用的有线/Wi-Fi 网络及可恢复的代理方案。保留 Windows Boot Manager，不格式化现有 Windows 或 ESP 分区。Windows 中关闭 Fast Startup；不要从 Linux 写入处于休眠状态的 Windows 文件系统。当前保留 `hardwareClockInLocalTime = true`；不要同时把 Windows 切到 UTC 而不修改 NixOS。

BIOS 选 Hybrid/混合显卡模式；当前配置不实现 Secure Boot 签名链，启用 Secure Boot 时需要单独完成签名集成，或在安装准备中明确选择关闭。不要误把 dGPU-only 模式下的黑屏当成 Lua 问题。

从 Live 环境收集事实（输出自行保存在本机，公开前审阅）：

```bash
lscpu
free -h
lsblk -f
findmnt
lspci -nnk
cat /sys/firmware/efi/fw_platform_size
cat /sys/power/mem_sleep
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver
cat /sys/firmware/acpi/platform_profile_choices
ls /sys/class/power_supply
```

后两个 CPU/平台文件可能不存在；这就是待判断信息。重点确认 AMD `05:00.0` 与 NVIDIA `01:00.0`、NVMe/文件系统、ESP 大小和挂载点、RAM/已有 swap。选择磁盘 swap、zram、休眠方式要依据这些结果：zram 与磁盘 swap 可以共存，zram 本身不能保存断电休眠镜像。当前不预设 swap 大小，也不启用休眠。

分区和挂载由你在安装现场确认，本仓库不自动执行。继续前必须确认目标根已经挂到 `/mnt`，**现有 ESP** 挂到 `/mnt/boot`（若选择其他挂载点，同时调整 Host 的 `boot.loader.efi.efiSysMountPoint` 和硬件配置）。检查 ESP 可用空间，10 个 generation 的内核/initrd 可能放不下小容量 Windows ESP；应减少 `configurationLimit` 或制定明确的引导布局，不直接扩大/格式化分区。

```bash
findmnt /mnt
findmnt /mnt/boot
ls /mnt/boot/EFI
# 确认挂载与 EFI/Microsoft 内容后，才生成设备配置：
sudo nixos-generate-config --root /mnt
```

把本仓库放到目标文件系统中，例如 `/mnt/etc/nixos/dotfiles/`。生成器产生的 `/mnt/etc/nixos/configuration.nix` 不作为本 flake 的入口。进入实际 flake 目录：

```bash
cd /mnt/etc/nixos/dotfiles/nixos
cp /mnt/etc/nixos/hardware-configuration.nix hosts/Ac0-Nomad/hardware-configuration.nix
```

审阅该文件的真实 UUID、`/` 与 `/boot` 挂载、initrd 模块和 swap。不要复制本文未提供的虚构 UUID；不要把 Live USB 自己的根挂载写入目标配置。

## 2. 所有输入、缓存与锁

当前只需两个 Flake inputs：nixpkgs 与 Home Manager。Hyprland **不是**额外 input，来自锁定 nixpkgs（0.56.2）；HM 的 nixpkgs follows 根输入。

```bash
python3 scripts/check-network.py
```

脚本读取 flake/lock，检查两个输入的 GitHub API 和 codeload 入口，以及 USTC/官方缓存；现在会明确报告 HM 锁缺失。退出码 2 表示锁/配置阻塞，1 表示网络探测失败。HTTP 成功不是 NAR 验证，也不保证所有包均有缓存。当前配置使用官方签名和 `require-sigs`，没有第三方未知公钥。

在 Live 会话先启用 Flakes 与安装阶段缓存（安装后的 `nix.settings` 不会倒过来配置 Live 环境）：

```bash
export NIX_CONFIG='experimental-features = nix-command flakes
substituters = https://mirrors.ustc.edu.cn/nix-channels/store?priority=30 https://cache.nixos.org?priority=40
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
require-sigs = true'
cp flake.lock /tmp/Ac0-Nomad-flake.lock.before
nix flake lock "path:$PWD"
git diff -- flake.lock
python3 scripts/check-network.py --offline
```

**这里使用 `lock` 补齐缺项，不执行 `flake update`。** nixpkgs 应仍为 `09063bd1f2b36fd9fd793c36dfade7bd40a93dfc`，NAR hash 应仍为 `sha256-Mh0PUaIv4nFY+8wAGonaEh8iBzwsmdNlwjVHmFg1Biw=`。Home Manager 应锁到 `82ce401aa350502897c3f2e85f384d61cd3b0b6d`，其 NAR hash 必须由 Nix 计算。可检查现有 nixpkgs 节点未被改变：

```bash
python3 - <<'PY'
import json
before = json.load(open('/tmp/Ac0-Nomad-flake.lock.before'))
after = json.load(open('flake.lock'))
assert before['nodes']['nixpkgs'] == after['nodes']['nixpkgs']
print('Existing nixpkgs lock preserved')
PY
```

若 GitHub 失败：先区分 DNS/TLS、HTTP 403 限流、代理失效与缓存 404，查看 `nix ... --show-trace -L` 的实际失败 URL。本次执行端的两个 archive API 与 codeload 下载成功，但提交查询 API 曾返回 403，不能据此保证目标网络可靠。若使用代理，客户端 fetch 与 nix-daemon 构建下载的网络环境需要分别验证；不要把代理凭据写入仓库，也不要通过 `curl -k` 或关闭签名绕过验证。

可采用同一官方仓库 **固定提交** 的 codeload 分发，不使用移动的 USTC channel archive冒充该 revision。流程：

1. 在有 Nix 和可用网络的机器预取并保存 JSON：

   ```bash
   nix flake prefetch --json 'tarball+https://codeload.github.com/NixOS/nixpkgs/tar.gz/09063bd1f2b36fd9fd793c36dfade7bd40a93dfc'
   nix flake prefetch --json 'tarball+https://codeload.github.com/nix-community/home-manager/tar.gz/82ce401aa350502897c3f2e85f384d61cd3b0b6d'
   ```

2. 比较 nixpkgs 解包后的 `hash` 与旧 lock 的 `narHash`；不一致就停止调查（不是比较压缩包 SHA256）。HM 如已经锁定，也必须比较旧 NAR hash。
3. 如果选择长期使用此分发，分别把 `flake.nix` 两个 URL 改成上面对应的 `tarball+https://...`，保持 `follows`。运行 `nix flake lock` 生成新锁，再审阅 URL 与 NAR hash。不要只用临时 `--override-input` 留下另一种不一致。
4. 当前诊断脚本针对仓库的 GitHub 输入格式，切换格式后它会提示手工检查；相应扩展诊断脚本并检查两个 tarball，不能把该提示忽略成通过。同样的 revision 并不免除真实求值和构建。

如果这两条分发路径都不可达，先解决网络，或在可信的 Nix 机器构建完整系统闭包后用 `nix copy --to file:///... <store-path>` 离线转移，再在目标 `nix copy --from file:///... <store-path>` 导入；还需携带仓库、锁及安装工具所需输入。不要承诺“换缓存就解决 GitHub”：binary cache 不代替所有 Flake inputs 和源码下载。

## 3. 首次构建与安装

完成硬件文件与锁之后：

```bash
nix flake metadata --no-write-lock-file "path:$PWD"
nix flake check --no-write-lock-file "path:$PWD"
nix build --no-write-lock-file "path:$PWD#nixosConfigurations.Ac0-Nomad.config.system.build.toplevel" -L
```

`flake check` 不等于完整系统构建，必须完成最后一步。任何 assertions、缺失选项、包构建或源获取错误都要先处理。实际构建成功才允许安装。

以下命令会在目标系统安装并写入引导器，只在确认 `/mnt` 挂载正确、Windows/EFI 有恢复备份后由你执行：

```bash
sudo --preserve-env=NIX_CONFIG nixos-install --root /mnt --flake "path:$PWD#Ac0-Nomad"
# nixos-install 会要求设置 root 密码；本配置没有默认用户密码。
sudo nixos-enter --root /mnt -c 'passwd xboxzzaw13'
```

**重启前必须完成普通用户密码设置**，并确认 `/mnt/etc/passwd` 中用户存在、`/mnt/boot/loader/entries` 中有 NixOS 条目、Windows EFI 文件仍在。可用 `sudo nixos-enter --root /mnt -c 'passwd -S xboxzzaw13'` 检查用户未被锁定。安装后保存 root 恢复口令在密码管理器中，不写入公开仓库。

## 4. 首次登录与桌面验收

先用 Ctrl+Alt+F2 进入 TTY，验证用户口令、`sudo -v`、网络和 `git`/`vim`。然后回 greetd，选择/启动默认 Hyprland 会话。备用 TTY 启动方式是 `uwsm start -e -D Hyprland hyprland.desktop`；不要同时运行两个同用户图形会话。

```bash
hyprctl version
hyprctl configerrors
hyprctl monitors all
systemctl --user --failed
systemctl --user status graphical-session.target waybar hypridle cliphist polkit-gnome
systemctl --user show-environment
pgrep -a fcitx5
fcitx5-diagnose
```

环境输出只本地检查，含个人变量时不要公开。确认 Lua 文件位于 `~/.config/hypr/hyprland.lua`、Host 文件位于同目录；`hyprctl configerrors` 无错误。内屏若不是 `eDP-1`，修改 `hosts/Ac0-Nomad/hyprland.lua` 后 rebuild + reload。外屏应自动选 preferred mode/自动缩放；测试插拔、热插拔时工作区转移、合盖外接屏和无外屏合盖。Docked 合盖忽略挂起由 logind 判断；是否需要额外关闭内屏应按实测决定，当前没有未经验证的 lid 脚本。

验证 Ctrl+Alt+L 锁屏及口令解锁、5 分钟空闲锁屏、10 分钟熄屏/恢复、`systemctl suspend` 后仍锁定；**确认锁屏可靠后才日常使用挂起**。hypridle 0.1.8 使用 `inhibit_sleep = 3` 等待锁定通知，但 logind inhibitor 有超时，配置不能替代真实测试。通知可用 `notify-send Test` 或截图触发；检查 `journalctl --user -b -u hypridle`。

用 [KEYBINDINGS.md](KEYBINDINGS.md) 验证启动、焦点、移动/调整尺寸、工作区、暂存区、媒体键；截图 Esc 后原剪贴板不应改变。`cliphist list` 会暴露复制历史，请勿贴到公共日志；`cliphist wipe` 可清除历史。剪贴板历史可能包含复制的密码，不将历史目录备份进公开仓库。

中文输入逐一测试 Firefox、GTK、Qt、终端和 XWayland 应用。fcitx5 只应有一个实例；Ctrl+Space 切到拼音。系统不全局设置 `GTK_IM_MODULE`/`QT_IM_MODULE`，优先 Wayland text-input；不支持该协议的 Qt 应用可单独用 `QT_IM_MODULE=fcitx <应用>`，XWayland 使用 `XMODIFIERS=@im=fcitx`。不为所有应用强加同一个后端。

测试 Firefox 文件选择和屏幕共享；检查 `journalctl --user -b -u xdg-desktop-portal -u xdg-desktop-portal-hyprland`。HM 激活失败查看 `systemctl status home-manager-xboxzzaw13.service`；已有文件冲突会产生 `.hm-backup`，先整理备份，不反复覆盖。

## 5. GPU、音频、电源、容器

```bash
ls -l /dev/dri/amd-igpu /dev/dri/nvidia-dgpu
lspci -nnk -s 05:00.0
lspci -nnk -s 01:00.0
nvidia-smi
cat /proc/driver/nvidia/gpus/0000:01:00.0/power
cat /sys/bus/pci/devices/0000:01:00.0/power/control
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status
```

`nvidia-smi` 本身会唤醒独显，不要循环运行它来判断空闲功耗。结束 GPU 程序/断开独显直连外屏，等待后读 sysfs，检查是否 suspended。从 Hyprland 日志确认 renderer 是 AMD，不能仅凭 PRIME 配置下结论。验证 `nvidia-offload` 可启动一个实际 OpenGL/Vulkan 应用并在运行时由 `nvidia-smi` 看到该进程。本机默认不安装测试游戏或 CUDA 框架；可用同锁定 nixpkgs 的 `mesa-demos`、`vulkan-tools` 临时 devShell 进行渲染器对比。

驱动预期为 stable 595.104.02/open，内核为默认 LTS 6.18.57；实际值以 build 后的 `uname -r` / `nvidia-smi` 为准。595 的 open 驱动由模块默认选择 kernel suspend notifier，不能再盲目叠加旧教程中的 suspend services/参数。保存显存可能占用驱动临时目录的磁盘空间，检查 `/tmp` 空间和是否被改为 tmpfs；若挂起失败，先保留日志再在 Host 明确选择合适的磁盘临时目录。

音频验收：

```bash
wpctl status
journalctl -k -b | rg -i 'cs35l41|CLSA0100|snd|firmware'
cat /proc/asound/card*/codec* | rg -i 'Codec:|Subsystem Id:'
```

确认型号实际 SSID、两个功放是否绑定、固件是否缺失；用 pavucontrol 验证左右声道、耳机切换、麦克风和睡眠恢复。源码包含该机支持并不证明你的 BIOS/硬件批次一定匹配。没有成功绑定时不要直接设置其他型号 `model=`、添加任意 ACPI override 或强灌寄存器。

电源验收：

```bash
sudo tlp-stat -s
sudo tlp-stat -p
sudo tlp-stat -b
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver
cat /sys/devices/system/cpu/cpu0/cpufreq/energy_performance_preference
systemctl is-active tlp power-profiles-daemon
```

插拔电源分别记录。TLP 应在运行，PPD 不应运行；若有 `amd-pstate-epp`，EPP 应按 AC/BAT 切换。5900HX 的 CPPC 暴露依赖 BIOS；若退回 `acpi-cpufreq`，EPP 不适用，记录 governor 与负载表现后为此 Host 调整策略，不宣称省电策略已经生效。必要时才试 `amd_pstate=active`，保留旧 generation 并测试睡眠。充电阈值只在 `tlp-stat -b`/sysfs 确认支持后添加，Legion conservation mode 不等于可任意设置百分比。

同一亮度、联网状态与空闲负载下，记录 UPower 的电池放电速率和 dGPU 状态；再对比外屏/不同 GPU 列表。没有测量就不填写续航数字。初次挂起/恢复测试先保存文件，不直接测试休眠。

容器用普通用户：

```bash
podman info --debug
systemctl status podman.socket
systemctl --user is-enabled podman.socket
```

确认 rootless、subuid/subgid 已分配，root socket 被 masked，用户 socket 没有自动启用。按需要选择可访问的可信 registry，用固定镜像 digest 测试运行与 volume UID。项目确实需要 Docker API 时才 `systemctl --user start podman.socket` 并为该项目设置 `DOCKER_HOST=unix://$XDG_RUNTIME_DIR/podman/podman.sock`。不全局伪装 docker 命令，不把自己加入高权限 podman/docker 组。

## 6. 已安装后的更新与回滚

进入实际仓库 `nixos/` 后，先备份改动与锁。Home Manager 是明确提交，普通 `nix flake update home-manager` 不会自动换到 master；升级它需要先选择/审计新提交并改 URL。常规维护先更新 nixpkgs，审查与 HM 的兼容性，再决定是否一起升级：

```bash
nix flake update nixpkgs --flake "path:$PWD"
git diff -- flake.lock
nix flake check --no-write-lock-file "path:$PWD"
sudo nixos-rebuild build --flake "path:$PWD#Ac0-Nomad"
```

检查 build 日志。纯用户配置/服务更改可以先在 TTY 中测试；内核/GPU/引导变化优先使用 boot，重启后可从旧引导项退回：

```bash
# 用户配置/服务试运行，不更新默认启动项：
sudo nixos-rebuild test --flake "path:$PWD#Ac0-Nomad"
# 满意后持久激活；会话相关更改建议从 TTY 执行：
sudo nixos-rebuild switch --flake "path:$PWD#Ac0-Nomad"
# 内核、GPU、引导相关更改用这一条，然后重启：
sudo nixos-rebuild boot --flake "path:$PWD#Ac0-Nomad"
```

回滚已切换的系统：

```bash
sudo nixos-rebuild switch --rollback
```

`test` 没有更新系统 profile，撤销它可运行 `/nix/var/nix/profiles/system/bin/switch-to-configuration switch`，或重启回默认 generation。图形服务配置回退后退出重登；内核/驱动回退需要重启。Home Manager 由系统 activation 恢复声明式文件，但不会回滚浏览器资料、用户词典、容器数据、密码和其他可变数据；依赖数据备份。

每周 GC 清理超过 30 天的旧 generation/store 路径。systemd-boot 菜单最多 10 项，不能保证任何旧版本永久可用。重大升级前保存已知良好系统路径并按需创建 GC root：

```bash
sudo ln -s "$(readlink -f /run/current-system)" /nix/var/nix/gcroots/ac0-known-good
```

该命令固定当前真实 store 路径；若同名 root 已存在，先审阅其指向再决定是否替换。保存旧仓库/锁并记录对应 generation；GC root 只保留系统闭包，不增加引导菜单项。

## 7. 启动/登录失败

- 图形失败：Ctrl+Alt+F2 登录，`journalctl -b -u greetd`、`journalctl --user -b`，修复或回滚。若用户密码没设，可用安装时设置的 root 密码进入 TTY 后 `passwd xboxzzaw13`。
- 新内核/驱动黑屏：开机按住 Space 进入 systemd-boot，选旧 generation。必要时编辑本次启动项加入 `systemd.unit=multi-user.target` 进入无图形维护模式；这不会修复所有内核早期故障。
- 所有 generation 都失败：从 UEFI Live USB 启动，按真实布局重新挂载目标根到 `/mnt` 与 ESP 到 `/mnt/boot`，检查 Windows EFI 备份。用 `sudo nixos-enter --root /mnt` 进入；查看 `/nix/var/nix/profiles/system-*-link`，将 system profile 切到已知良好 generation，再运行其 `bin/switch-to-configuration boot` 恢复下次启动项。操作前核对路径，勿清理旧闭包。

例如在 chroot 内，先 `nix-env --profile /nix/var/nix/profiles/system --list-generations`，再用核对后的编号执行 `nix-env --profile /nix/var/nix/profiles/system --switch-generation <编号>` 和 `/nix/var/nix/profiles/system/bin/switch-to-configuration boot`。这涉及恢复引导，仅在正确挂载的目标系统内执行。无可用 generation 时用修复后的仓库重新 build/install；不要重新分区来处理配置错误。

# 多设备 NixOS 架构

本仓库以显式 `imports` 组合功能，不引入自定义 option 框架、目录扫描或额外的硬件 flake。Flake 根是 `nixos/`，第一个输出保留为 `nixosConfigurations.Ac0-Nomad`。当前交付尚未经过 Nix 求值或目标硬件验收，先阅读 [DEPLOYMENT.md](DEPLOYMENT.md)。

## 结构与职责

```text
nixos/
├── flake.nix / flake.lock        输入、Host 输出、仓库维护 devShell
├── configuration.nix            通用系统基线、缓存、网络、防火墙、TTY 工具
├── home.nix                     共享 Bash、Git、SSH 客户端、CLI、Neovim
├── modules/
│   ├── hyprland.nix              系统会话、greetd、portal、PAM、音频、字体、输入法
│   ├── laptop.nix                蓝牙、固件更新、TLP、合盖策略
│   ├── nvidia.nix                可选现代 NVIDIA 驱动，不包含 PCI 拓扑
│   └── containers.nix            可选 rootless Podman，屏蔽 root API
├── home/
│   ├── development.nix           tmux、direnv/nix-direnv、小型 Python 基线
│   └── hyprland.nix              桌面软件、用户服务、锁屏、Lua 和辅助脚本部署
├── hosts/Ac0-Nomad/
│   ├── default.nix              功能选择、用户、stateVersion、引导、GPU、电源边界
│   ├── home.nix                 用户身份、home.stateVersion、用户模块、UWSM GPU 环境
│   ├── hyprland.lua             内屏缩放；连接器名待实机确认
│   └── hardware-configuration.nix  安装现场生成，当前不存在且被 Git 忽略
├── config/wm/hypr/hyprland.lua   通用键盘工作流、自动显示器规则
├── scripts/                     截图、剪贴板、快捷键检查、网络诊断
└── ARCHITECTURE / DEPLOYMENT / KEYBINDINGS / CHANGES.md
```

`configuration.nix` 和 `home.nix` 仍是有实际内容的共享模块，不再直接代表 Legion。系统层只保留维修工具和系统集成功能；浏览器、终端、编辑器及工作流在 Home Manager 中。

Home Manager 作为 NixOS 模块随系统 generation 激活，使用 `useGlobalPkgs` 与 `useUserPackages`，不单独维护另一套 nixpkgs。不运行独立 `home-manager switch`；统一用本仓库的 `nixos-rebuild`。新文件通过 Nix store 部署，没有指向工作区的可变链接。发生文件冲突时保留 `.hm-backup`，重复冲突需人工整理后再激活。

## 会话所有权

启动链为 greetd → tuigreet → `uwsm start -e -D Hyprland hyprland.desktop`。NixOS 安装同一锁定 nixpkgs 中的 Hyprland 和 portal；Home Manager 的 Hyprland `package`、`portalPackage` 为 `null`，只生成 Lua，`systemd.enable = false`，避免第二套会话 target。

UWSM 管理 `graphical-session.target` 和 XDG autostart。Waybar、hypridle、cliphist、polkit agent 随用户图形会话启动/停止；mako 按 D-Bus 需求激活；fcitx5 使用包提供的 XDG autostart，Lua 不再启动它。单个 cliphist watcher 记录普通剪贴板，不记录鼠标主选区。Home Manager 部署声明式 fcitx profile（US 键盘与拼音）；个人词典不在仓库中，修改输入法列表应编辑该配置。

Hyprland 的全局默认外观不被替换；Waybar 无自定义 CSS；锁屏只配必要背景和密码框。设备 Lua 经 HM `extraLuaFiles` 加载，共享 Lua 是 `extraConfig` 的实际输入。键位表从运行此 Lua 的静态记录生成，见 [KEYBINDINGS.md](KEYBINDINGS.md)。

修改 Lua 后需要 rebuild 才会更改 store 中的部署文件。因为 HM 不拥有 compositor package，不依赖它自动调用 reload；成功激活后按 Super+Ctrl+R 或运行 `hyprctl reload`。包、GPU 环境或会话服务变化则退出重登，内核/驱动变化重启。

## 新增笔记本

1. 建立 `hosts/<实际主机名>/default.nix`，导入共享基线与需要的功能模块。
2. 在新设备生成自己的 `hardware-configuration.nix`；不要复制 Legion 的 UUID、Bus ID、引导布局或 `AQ_DRM_DEVICES`。
3. 在新 Host 选择架构、引导方式、用户、首次安装适用的 `system.stateVersion`。新用户环境单独选择 `home.stateVersion`；已有 home 数据迁移时保留旧值并阅读迁移说明。
4. 建立 Host 的 `home.nix`，导入 `../../home.nix`，按需导入开发/桌面模块。显示器规则、个人设备差异只放这里或对应 Host Lua。
5. 在 flake 的 `nixosConfigurations` 中显式增加一个 `nixpkgs.lib.nixosSystem`，导入新 Host 与同一 Home Manager 模块/公共集成设置。当前只有一个 Host，尚不为这几行集成创建工厂函数。
6. 完成真实求值、构建和新硬件验收。新增 aarch64 主机时不要沿用 x86 架构，也不要默认导入 NVIDIA 模块。

## 功能启停与 GPU 边界

| 能力 | 启用方式 | 关闭时注意 |
| --- | --- | --- |
| Hyprland 桌面 | 同时导入 `modules/hyprland.nix` 与 `home/hyprland.nix` | 同时移除 Host 的桌面 Lua/UWSM 设置；TTY 仍可用 |
| 笔记本 | 导入 `modules/laptop.nix` | 桌面不依赖它；无电池时 Waybar 电池模块不显示 |
| 开发工作站 | 导入 `home/development.nix` | 保留通用 Shell/Git/Neovim；不加载项目目录的 `.envrc` |
| 本地容器 | 导入 `modules/containers.nix` | 远程 SSH 容器开发不需要本地引擎 |
| NVIDIA | 导入 `modules/nvidia.nix` | Host 单独决定 offload、Bus ID、RTD3；老 GPU 需另一驱动策略 |
| CUDA/GPU 容器 | 当前不默认启用 | 按项目与驱动兼容性再接入 |

Legion 明确选用 AMD 主渲染、NVIDIA offload。稳定 udev 别名将 AMD 放在 `AQ_DRM_DEVICES` 首位，同时列入 NVIDIA 以保留独显直连外屏。这不能保证 NVIDIA 始终休眠；外屏接线、compositor 打开 DRM 设备及 BIOS 模式都要验证。仅需内屏且确认外屏不依赖 NVIDIA 时，可在该 Host 改为只列 AMD 后重登对比功耗。

未来 AMD/Intel 单显卡主机通常不导入 NVIDIA 模块，并让 NixOS/内核自动识别；需要额外固件、VA-API 或显示配置时在自己的 Host 添加。不同 GPU 不改变共享键位。NVIDIA 模块使用 open 内核模块，支持范围从 Turing 起，不能无条件套到旧显卡。

电源模块只运行 TLP，自动切换 AC/BAT；Legion 的 CPPC/amd-pstate 可用性待测。不把 `amd_pstate=active`、充电阈值、强制音频 `model=` 或未知 swap 布局写入通用配置。RAM 未知，暂不新增 zram/磁盘 swap；后续可同时配置两者，以 swap 优先级安排使用顺序。休眠另需磁盘 swap、容量和 resume 路径验收。

## 项目开发与未来 CUDA

仓库 `nix develop 'path:.'` 只提供配置维护工具。应用仓库应维护自己的 flake、lock、`.envrc`（内容 `use flake`），审阅后执行 `direnv allow`。让 LSP、编译器和项目 Python 从 devShell 中启动，不全局安装每个语言版本。`nix-direnv` 减少重复求值；项目锁独立于系统更新。

未来 CUDA 项目可以从下面的最小 devShell 扩展（示意，未构建/未上机）：

```nix
# 项目自己的 flake.nix；由 nix flake lock 产生项目锁。
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/09063bd1f2b36fd9fd793c36dfade7bd40a93dfc";
  outputs = { nixpkgs, ... }: let
    pkgs = import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; };
  in {
    devShells.x86_64-linux.default = pkgs.mkShell {
      packages = [ pkgs.python3 pkgs.cudaPackages.cuda_nvcc ];
      # CUDA 用户态工具由项目提供，libcuda 驱动来自正在运行的 NixOS 系统。
      shellHook = ''
        export LD_LIBRARY_PATH=/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
      '';
    };
  };
}
```

这只是 nvcc 入门环境，**不代表** PyTorch、pip wheel、完整 CUDA SDK、RL 模拟器或 EGL/Vulkan 已配置。下一步按项目选择 nixpkgs 的 CUDA package set、Python/PyTorch CUDA 构建或固定版本的容器镜像，核对驱动最低版本、编译器范围、显存和各依赖的二进制库。不要全局设置 `nixpkgs.config.cudaSupport = true`。不把驱动包复制进每个项目，也不全局设置 `LD_LIBRARY_PATH`。

远程训练用 SSH、tmux 与远端项目环境，本机不必安装 CUDA，也不必开启 sshd。将来需要本地 GPU 容器时，在 NVIDIA Host 按版本审计后启用 `hardware.nvidia-container-toolkit.enable`，检查生成的 CDI 规格，再用 `podman run --device nvidia.com/gpu=all ...`；当前未启用也未验证。不要使用已弃用的 `virtualisation.podman.enableNvidia`。

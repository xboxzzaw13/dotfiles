# Hyprland 快捷键

由 `lua scripts/check-keybindings.lua --write` 从实际 Lua 配置生成。Super 是 Windows 键。方向键与 h/j/k/l 均可使用；主键不区分大小写。

除媒体/音量/亮度键外，锁屏时禁用桌面快捷键。Ctrl+Alt+F2 切换维护 TTY（系统功能），Ctrl+Space 是 fcitx5 默认输入法切换键。注销可在终端执行 `uwsm stop`，请先保存工作。

| 快捷键 | 作用 | 应用/实际命令 | 场景 |
| --- | --- | --- | --- |
| SUPER + Return | 终端 | `uwsm app -- kitty` | 命令行 |
| SUPER + D | 应用启动器 | `rofi -show drun -show-icons` | 启动桌面应用 |
| SUPER + E | 文件管理 | `uwsm app -- kitty -e yazi` | 浏览文件 |
| SUPER + W | 浏览器 | `uwsm app -- firefox` | 网页 |
| SUPER + C | 编辑器 | `uwsm app -- kitty -e nvim` | 编辑文件 |
| SUPER + B | 资源监视器 | `uwsm app -- kitty -e btop` | 进程与负载 |
| SUPER + V | 剪贴板历史 | `desktop-clipboard` | 选择文字或图片 |
| SUPER + N | 网络设置 | `uwsm app -- kitty -e nmtui` | 连接 Wi-Fi |
| SUPER + CTRL + B | 蓝牙设置 | `blueman-manager` | 配对设备（笔记本模块） |
| SUPER + CTRL + V | 音频设置 | `pavucontrol` | 选择输入输出设备 |
| SUPER + Q | 关闭窗口 | `Hyprland` | 正常退出应用 |
| SUPER + SHIFT + Q | 强制关闭窗口 | `Hyprland` | 仅用于无响应应用；未保存数据会丢失 |
| SUPER + F | 切换全屏 | `Hyprland` | 专注当前窗口 |
| SUPER + M | 切换最大化 | `Hyprland` | 保留面板的专注模式 |
| SUPER + Space | 切换浮动 | `Hyprland` | 对话框或临时布局 |
| SUPER + P | 切换伪平铺 | `Hyprland` | dwindle 保持窗口尺寸 |
| SUPER + T | 切换分割方向 | `Hyprland` | dwindle 布局 |
| SUPER + Tab | 循环聚焦窗口 | `Hyprland` | 当前工作区；替代 rofi 的 X11 window 模式 |
| SUPER + grave | 循环聚焦窗口 | `Hyprland` | 保留原有入口 |
| SUPER + Left | 向左聚焦 | `Hyprland` | 相邻窗口/显示器 |
| SUPER + CTRL + Left | 向左移动窗口 | `Hyprland` | 调整窗口位置 |
| SUPER + ALT + Left | 向左交换窗口 | `Hyprland` | 调整平铺顺序 |
| SUPER + SHIFT + Left | 调整尺寸 -50,0 | `Hyprland` | 步长 50 像素 |
| SUPER + h | 向左聚焦 | `Hyprland` | 相邻窗口/显示器 |
| SUPER + CTRL + h | 向左移动窗口 | `Hyprland` | 调整窗口位置 |
| SUPER + ALT + h | 向左交换窗口 | `Hyprland` | 调整平铺顺序 |
| SUPER + SHIFT + h | 调整尺寸 -50,0 | `Hyprland` | 步长 50 像素 |
| SUPER + Right | 向右聚焦 | `Hyprland` | 相邻窗口/显示器 |
| SUPER + CTRL + Right | 向右移动窗口 | `Hyprland` | 调整窗口位置 |
| SUPER + ALT + Right | 向右交换窗口 | `Hyprland` | 调整平铺顺序 |
| SUPER + SHIFT + Right | 调整尺寸 50,0 | `Hyprland` | 步长 50 像素 |
| SUPER + l | 向右聚焦 | `Hyprland` | 相邻窗口/显示器 |
| SUPER + CTRL + l | 向右移动窗口 | `Hyprland` | 调整窗口位置 |
| SUPER + ALT + l | 向右交换窗口 | `Hyprland` | 调整平铺顺序 |
| SUPER + SHIFT + l | 调整尺寸 50,0 | `Hyprland` | 步长 50 像素 |
| SUPER + Up | 向上聚焦 | `Hyprland` | 相邻窗口/显示器 |
| SUPER + CTRL + Up | 向上移动窗口 | `Hyprland` | 调整窗口位置 |
| SUPER + ALT + Up | 向上交换窗口 | `Hyprland` | 调整平铺顺序 |
| SUPER + SHIFT + Up | 调整尺寸 0,-50 | `Hyprland` | 步长 50 像素 |
| SUPER + k | 向上聚焦 | `Hyprland` | 相邻窗口/显示器 |
| SUPER + CTRL + k | 向上移动窗口 | `Hyprland` | 调整窗口位置 |
| SUPER + ALT + k | 向上交换窗口 | `Hyprland` | 调整平铺顺序 |
| SUPER + SHIFT + k | 调整尺寸 0,-50 | `Hyprland` | 步长 50 像素 |
| SUPER + Down | 向下聚焦 | `Hyprland` | 相邻窗口/显示器 |
| SUPER + CTRL + Down | 向下移动窗口 | `Hyprland` | 调整窗口位置 |
| SUPER + ALT + Down | 向下交换窗口 | `Hyprland` | 调整平铺顺序 |
| SUPER + SHIFT + Down | 调整尺寸 0,50 | `Hyprland` | 步长 50 像素 |
| SUPER + j | 向下聚焦 | `Hyprland` | 相邻窗口/显示器 |
| SUPER + CTRL + j | 向下移动窗口 | `Hyprland` | 调整窗口位置 |
| SUPER + ALT + j | 向下交换窗口 | `Hyprland` | 调整平铺顺序 |
| SUPER + SHIFT + j | 调整尺寸 0,50 | `Hyprland` | 步长 50 像素 |
| SUPER + 1 | 工作区 1 | `Hyprland` | 0 对应工作区 10 |
| SUPER + SHIFT + 1 | 移动窗口到工作区 1 | `Hyprland` | 随窗口切换 |
| SUPER + 2 | 工作区 2 | `Hyprland` | 0 对应工作区 10 |
| SUPER + SHIFT + 2 | 移动窗口到工作区 2 | `Hyprland` | 随窗口切换 |
| SUPER + 3 | 工作区 3 | `Hyprland` | 0 对应工作区 10 |
| SUPER + SHIFT + 3 | 移动窗口到工作区 3 | `Hyprland` | 随窗口切换 |
| SUPER + 4 | 工作区 4 | `Hyprland` | 0 对应工作区 10 |
| SUPER + SHIFT + 4 | 移动窗口到工作区 4 | `Hyprland` | 随窗口切换 |
| SUPER + 5 | 工作区 5 | `Hyprland` | 0 对应工作区 10 |
| SUPER + SHIFT + 5 | 移动窗口到工作区 5 | `Hyprland` | 随窗口切换 |
| SUPER + 6 | 工作区 6 | `Hyprland` | 0 对应工作区 10 |
| SUPER + SHIFT + 6 | 移动窗口到工作区 6 | `Hyprland` | 随窗口切换 |
| SUPER + 7 | 工作区 7 | `Hyprland` | 0 对应工作区 10 |
| SUPER + SHIFT + 7 | 移动窗口到工作区 7 | `Hyprland` | 随窗口切换 |
| SUPER + 8 | 工作区 8 | `Hyprland` | 0 对应工作区 10 |
| SUPER + SHIFT + 8 | 移动窗口到工作区 8 | `Hyprland` | 随窗口切换 |
| SUPER + 9 | 工作区 9 | `Hyprland` | 0 对应工作区 10 |
| SUPER + SHIFT + 9 | 移动窗口到工作区 9 | `Hyprland` | 随窗口切换 |
| SUPER + 0 | 工作区 10 | `Hyprland` | 0 对应工作区 10 |
| SUPER + SHIFT + 0 | 移动窗口到工作区 10 | `Hyprland` | 随窗口切换 |
| SUPER + bracketleft | 上一个工作区 | `Hyprland` | 遍历已有工作区 |
| SUPER + bracketright | 下一个工作区 | `Hyprland` | 遍历已有工作区 |
| SUPER + S | 切换暂存区 | `Hyprland` | 临时任务；无应用自动启动 |
| SUPER + ALT + S | 把窗口送进暂存区 | `Hyprland` | 隐藏窗口；用 Super+Shift+数字移回普通工作区 |
| SUPER + mouse:272 | 拖动窗口 | `Hyprland` | Super+左键拖动 |
| SUPER + mouse:273 | 调整窗口尺寸 | `Hyprland` | Super+右键拖动 |
| CTRL + ALT + L | 锁屏 | `loginctl lock-sessions` | 锁定本机登录会话；由 hypridle 调用 hyprlock |
| Print | 截图全部显示器 | `desktop-screenshot all` | 复制到剪贴板；锁屏期间禁用 |
| SUPER + SHIFT + S | 区域截图 | `desktop-screenshot area` | 拖选区域；Esc 取消且保留剪贴板 |
| SUPER + CTRL + R | 重新加载桌面配置 | `hyprctl reload` | 应用已部署的配置；不创建 Nix generation |
| XF86AudioRaiseVolume | 音量加 5% | `wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+` | 锁屏时也可用 |
| XF86AudioLowerVolume | 音量减 5% | `wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-` | 锁屏时也可用 |
| XF86AudioMute | 切换静音 | `wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle` | 锁屏时也可用 |
| XF86AudioMicMute | 切换麦克风静音 | `wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle` | 锁屏时也可用 |
| XF86MonBrightnessUp | 亮度增加 | `brightnessctl -e4 -n2 set 5%+` | 锁屏时也可用 |
| XF86MonBrightnessDown | 亮度降低 | `brightnessctl -e4 -n2 set 5%-` | 锁屏时也可用 |
| XF86AudioNext | 下一首 | `playerctl next` | 锁屏时也可用 |
| XF86AudioPrev | 上一首 | `playerctl previous` | 锁屏时也可用 |
| XF86AudioPlay | 播放/暂停 | `playerctl play-pause` | 锁屏时也可用 |
| XF86AudioPause | 播放/暂停 | `playerctl play-pause` | 锁屏时也可用 |

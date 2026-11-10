-- Hyprland 0.56.2. Visual defaults stay upstream; device rules live in hosts/.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
hl.config({
    input = { kb_layout = "us" },
    dwindle = { preserve_split = true },
})

-- Return metadata so scripts/check-keybindings.lua can verify and document the
-- actual expanded bindings, including loops. Nothing here starts a daemon.
local bindings = {}
local function bind(key, action, description, app, scenario, options)
    options = options or {}
    options.description = description
    hl.bind(key, action, options)
    bindings[#bindings + 1] = { key, description, app, scenario }
end
local function app(key, command, description, scenario)
    bind(key, hl.dsp.exec_cmd(command), description, command, scenario)
end
local mod = "SUPER"
app(mod .. " + Return", "uwsm app -- kitty", "终端", "命令行")
app(mod .. " + D", "rofi -show drun -show-icons", "应用启动器", "启动桌面应用")
app(mod .. " + E", "uwsm app -- kitty -e yazi", "文件管理", "浏览文件")
app(mod .. " + W", "uwsm app -- firefox", "浏览器", "网页")
app(mod .. " + C", "uwsm app -- kitty -e nvim", "编辑器", "编辑文件")
app(mod .. " + B", "uwsm app -- kitty -e btop", "资源监视器", "进程与负载")
app(mod .. " + V", "desktop-clipboard", "剪贴板历史", "选择文字或图片")
app(mod .. " + N", "uwsm app -- kitty -e nmtui", "网络设置", "连接 Wi-Fi")
app(mod .. " + CTRL + B", "blueman-manager", "蓝牙设置", "配对设备（笔记本模块）")
app(mod .. " + CTRL + V", "pavucontrol", "音频设置", "选择输入输出设备")

bind(mod .. " + Q", hl.dsp.window.close(), "关闭窗口", "Hyprland", "正常退出应用")
bind(mod .. " + SHIFT + Q", hl.dsp.window.kill(), "强制关闭窗口", "Hyprland", "仅用于无响应应用；未保存数据会丢失")
bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), "切换全屏", "Hyprland", "专注当前窗口")
bind(mod .. " + M", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }), "切换最大化", "Hyprland", "保留面板的专注模式")
bind(mod .. " + Space", hl.dsp.window.float({ action = "toggle" }), "切换浮动", "Hyprland", "对话框或临时布局")
bind(mod .. " + P", hl.dsp.window.pseudo(), "切换伪平铺", "Hyprland", "dwindle 保持窗口尺寸")
bind(mod .. " + T", hl.dsp.layout("togglesplit"), "切换分割方向", "Hyprland", "dwindle 布局")
bind(mod .. " + Tab", hl.dsp.window.cycle_next(), "循环聚焦窗口", "Hyprland", "当前工作区；替代 rofi 的 X11 window 模式")
bind(mod .. " + grave", hl.dsp.window.cycle_next(), "循环聚焦窗口", "Hyprland", "保留原有入口")

local arrows = { "Left", "Right", "Up", "Down" }
local vim = { "h", "l", "k", "j" }
local directions = { "left", "right", "up", "down" }
local labels = { "左", "右", "上", "下" }
local dx, dy = { -50, 50, 0, 0 }, { 0, 0, -50, 50 }
for i = 1, 4 do
    for _, key in ipairs({ arrows[i], vim[i] }) do
        bind(mod .. " + " .. key, hl.dsp.focus({ direction = directions[i] }), "向" .. labels[i] .. "聚焦", "Hyprland", "相邻窗口/显示器")
        bind(mod .. " + CTRL + " .. key, hl.dsp.window.move({ direction = directions[i] }), "向" .. labels[i] .. "移动窗口", "Hyprland", "调整窗口位置")
        bind(mod .. " + ALT + " .. key, hl.dsp.window.swap({ direction = directions[i] }), "向" .. labels[i] .. "交换窗口", "Hyprland", "调整平铺顺序")
        bind(mod .. " + SHIFT + " .. key, hl.dsp.window.resize({ x = dx[i], y = dy[i], relative = true }), "调整尺寸 " .. dx[i] .. "," .. dy[i], "Hyprland", "步长 50 像素")
    end
end
for i = 1, 10 do
    local key = i % 10
    bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }), "工作区 " .. i, "Hyprland", "0 对应工作区 10")
    bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i, follow = true }), "移动窗口到工作区 " .. i, "Hyprland", "随窗口切换")
end
bind(mod .. " + bracketleft", hl.dsp.focus({ workspace = "e-1" }), "上一个工作区", "Hyprland", "遍历已有工作区")
bind(mod .. " + bracketright", hl.dsp.focus({ workspace = "e+1" }), "下一个工作区", "Hyprland", "遍历已有工作区")
bind(mod .. " + S", hl.dsp.workspace.toggle_special("magic"), "切换暂存区", "Hyprland", "临时任务；无应用自动启动")
bind(mod .. " + ALT + S", hl.dsp.window.move({ workspace = "special:magic", follow = false }), "把窗口送进暂存区", "Hyprland", "隐藏窗口；用 Super+Shift+数字移回普通工作区")
bind(mod .. " + mouse:272", hl.dsp.window.drag(), "拖动窗口", "Hyprland", "Super+左键拖动", { mouse = true })
bind(mod .. " + mouse:273", hl.dsp.window.resize(), "调整窗口尺寸", "Hyprland", "Super+右键拖动", { mouse = true })

-- Super+L is right focus (case-insensitive). Lock uses Ctrl+Alt+L.
app("CTRL + ALT + L", "loginctl lock-sessions", "锁屏", "锁定本机登录会话；由 hypridle 调用 hyprlock")
app("Print", "desktop-screenshot all", "截图全部显示器", "复制到剪贴板；锁屏期间禁用")
app(mod .. " + SHIFT + S", "desktop-screenshot area", "区域截图", "拖选区域；Esc 取消且保留剪贴板")
app(mod .. " + CTRL + R", "hyprctl reload", "重新加载桌面配置", "应用已部署的配置；不创建 Nix generation")

local media = {
    { "XF86AudioRaiseVolume", "wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+", "音量加 5%", true },
    { "XF86AudioLowerVolume", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-", "音量减 5%", true },
    { "XF86AudioMute", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", "切换静音", false },
    { "XF86AudioMicMute", "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle", "切换麦克风静音", false },
    { "XF86MonBrightnessUp", "brightnessctl -e4 -n2 set 5%+", "亮度增加", true },
    { "XF86MonBrightnessDown", "brightnessctl -e4 -n2 set 5%-", "亮度降低", true },
    { "XF86AudioNext", "playerctl next", "下一首", false },
    { "XF86AudioPrev", "playerctl previous", "上一首", false },
    { "XF86AudioPlay", "playerctl play-pause", "播放/暂停", false },
    { "XF86AudioPause", "playerctl play-pause", "播放/暂停", false },
}
for _, item in ipairs(media) do
    bind(item[1], hl.dsp.exec_cmd(item[2]), item[3], item[2], "锁屏时也可用", { locked = true, repeating = item[4] })
end
return bindings

-- ~/.config/hypr/hyprland.lua
-- 键盘优先配置（hacker 取向）：能用键盘就不碰鼠标
-- 主修饰键：SUPER（Win 键）
-- 目标机器：Legion R9000K / Hyprland + Lua 配置

------------------------------------------------------------------
-- 环境变量（必须排在其它 hl.* 之前）
------------------------------------------------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("MOZ_ENABLE_WAYLAND", "1")
-- 注意：不要设 LIBVA_DRIVER_NAME=nvidia。你是 offload 模式，
-- 桌面由 AMD iGPU 渲染，设了反而让 Firefox 硬解走错卡。

------------------------------------------------------------------
-- 显示器
------------------------------------------------------------------

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "1.33",
})

------------------------------------------------------------------
-- 程序名（改这里就能换）
------------------------------------------------------------------

local terminal    = "kitty"
local launcher    = "rofi -show drun -show-icons -icon-theme Papirus"
local fileManager = "kitty -e yazi"
local browser     = "firefox"

-- 电源菜单
local powerMenu = [[
choice=$(printf 'lock\nsuspend\nreboot\nshutdown' | rofi -dmenu -p 'power')
case "$choice" in
  lock)     hyprlock ;;
  suspend)  systemctl suspend ;;
  reboot)   systemctl reboot ;;
  shutdown) systemctl poweroff ;;
esac
]]

-- 剪贴板历史
local clipboard = "cliphist list | rofi -dmenu -display-columns 2 | cliphist decode | wl-copy"

-- 截图（选区 → 剪贴板）
local shotRegion = [[grim -g "$(slurp)" - | wl-copy]]
-- 截图（全屏 → 剪贴板）
local shotFull = "grim - | wl-copy"

------------------------------------------------------------------
-- 自启动
------------------------------------------------------------------

hl.on("hyprland.start", function()
    hl.exec_cmd("fcitx5 -d")                                   -- 输入法守护进程，NixOS 模块不会启动它
    hl.exec_cmd("waybar")
    hl.exec_cmd("mako")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("wl-paste --watch cliphist store")             -- 剪贴板监听（文本/图片）
    hl.exec_cmd("wl-paste --primary --watch cliphist store")   -- 主选区也记
end)

------------------------------------------------------------------
-- 外观：锐角、细边、无模糊（快 + 干净）
------------------------------------------------------------------

hl.config({
    general = {
        gaps_in  = 2,
        gaps_out = 6,

        border_size = 2,

        col = {
            active_border   = "rgba(00ff41ee)",   -- 磷光绿
            inactive_border = "rgba(1a1a1acc)",   -- 近黑
        },

        resize_on_border = false,
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding       = 0,      -- 直角，geek 味
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 0.92,

        shadow = {
            enabled = false,     -- 关阴影，省 GPU
        },

        blur = {
            enabled = false,     -- 关模糊，省 GPU
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
    },

    binds = {
        workspace_back_and_forth = true,
    },
})

-- 动画曲线：短促，不拖泥带水
hl.curve("quick", { type = "bezier", points = { {0.15, 0}, {0.1, 1} } })
hl.curve("linear", { type = "bezier", points = { {0, 0}, {1, 1} } })

hl.animation({ leaf = "global",       enabled = true, speed = 8,    bezier = "quick" })
hl.animation({ leaf = "border",       enabled = true, speed = 8,    bezier = "quick" })
hl.animation({ leaf = "windows",      enabled = true, speed = 6,    bezier = "quick" })
hl.animation({ leaf = "windowsIn",    enabled = true, speed = 6,    bezier = "quick", style = "popin 95%" })
hl.animation({ leaf = "windowsOut",   enabled = true, speed = 5,    bezier = "linear" })
hl.animation({ leaf = "fade",         enabled = true, speed = 6,    bezier = "quick" })
hl.animation({ leaf = "workspaces",   enabled = true, speed = 5,    bezier = "quick", style = "fade" })
hl.animation({ leaf = "layers",       enabled = true, speed = 6,    bezier = "quick" })

------------------------------------------------------------------
-- 输入
------------------------------------------------------------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,
        sensitivity  = 0,

        touchpad = {
            natural_scroll = false,
            -- tap-to-click 在 Hyprland 里默认就是 true，不用写；
            -- 真要写，键名含连字符必须用 ["tap-to-click"] = true
        },
    },
})

hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

------------------------------------------------------------------
-- 兜底：走 hyprctl dispatch（方向移动/缩放用，语义百分百确定）
------------------------------------------------------------------

local function hyd(cmd)
    return hl.dsp.exec_cmd("hyprctl dispatch " .. cmd)
end

-- vim 键 → Hyprland 方向字母
local vimToDir = {
    h = "l",
    j = "d",
    k = "u",
    l = "r",
}

-- vim 键 → 全称（给 hl.dsp.focus 用）
local vimToName = {
    h = "left",
    j = "down",
    k = "up",
    l = "right",
}

------------------------------------------------------------------
-- 键位
------------------------------------------------------------------

local mod = "SUPER"

------------------------------------------------------------------
-- 启动 / 唤起
------------------------------------------------------------------

hl.bind(mod .. " + Return", hl.dsp.exec_cmd(terminal))            -- 终端
hl.bind(mod .. " + D",      hl.dsp.exec_cmd(launcher))            -- 应用启动器
hl.bind(mod .. " + Tab",    hl.dsp.exec_cmd("rofi -show window")) -- 窗口切换
hl.bind(mod .. " + E",      hl.dsp.exec_cmd(fileManager))         -- 文件管理（yazi）
hl.bind(mod .. " + W",      hl.dsp.exec_cmd(browser))             -- 浏览器
hl.bind(mod .. " + N",      hl.dsp.exec_cmd("kitty -e nvim"))     -- 编辑器
hl.bind(mod .. " + B",      hl.dsp.exec_cmd("kitty -e btop"))     -- 资源监视

------------------------------------------------------------------
-- 窗口操作
------------------------------------------------------------------

hl.bind(mod .. " + Q",         hl.dsp.window.close())
hl.bind(mod .. " + SHIFT + Q", hl.dsp.window.kill())
hl.bind(mod .. " + F",         hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mod .. " + Space",     hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + P",         hl.dsp.window.pseudo())
hl.bind(mod .. " + T",         hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + grave",     hl.dsp.window.cycle_next())

-- vim 方向聚焦
for key, direction in pairs(vimToName) do
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ direction = direction }))
end

-- 方向移动窗口（在 tile 之间挪）
for key, d in pairs(vimToDir) do
    hl.bind(mod .. " + CTRL + " .. key, hyd("moveactive " .. d))
end

-- 方向交换两个窗口的位置
for key, d in pairs(vimToDir) do
    hl.bind(mod .. " + SHIFT + " .. key, hyd("swapwindow " .. d))
end

-- 键盘缩放（+/-）
hl.bind(mod .. " + minus",  hyd("resizeactive -40 0"))
hl.bind(mod .. " + equal",  hyd("resizeactive 40 0"))

------------------------------------------------------------------
-- 工作区
------------------------------------------------------------------

for i = 1, 10 do
    local key = i % 10
    hl.bind(mod .. " + " .. key,             hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
    hl.bind(mod .. " + CTRL + " .. key,      hl.dsp.window.move({ workspace = i }))  -- 带焦点过去
end

-- 工作区循环
hl.bind(mod .. " + bracketleft",  hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mod .. " + bracketright", hl.dsp.focus({ workspace = "e+1" }))

-- 暂存区（scratchpad）
hl.bind(mod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

------------------------------------------------------------------
-- 截图 / 剪贴板
------------------------------------------------------------------

hl.bind("Print",              hl.dsp.exec_cmd(shotFull),   { locked = true })
hl.bind(mod .. " + Print",    hl.dsp.exec_cmd(shotRegion), { locked = true })
hl.bind(mod .. " + V",        hl.dsp.exec_cmd(clipboard))

------------------------------------------------------------------
-- 系统
------------------------------------------------------------------

hl.bind(mod .. " + L",         hl.dsp.exec_cmd("hyprlock"))
hl.bind(mod .. " + SHIFT + E", hl.dsp.exec_cmd(powerMenu))

------------------------------------------------------------------
-- 媒体键
------------------------------------------------------------------

hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

------------------------------------------------------------------
-- 窗口规则
------------------------------------------------------------------

-- 忽略所有程序的「最大化」请求：tiling 下没意义
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

-- XWayland 拖拽残影修复
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- 浮动小窗（截图工具、图片查看、计算器）
hl.window_rule({
    name  = "float-small-tools",
    match = { class = "^(swappy|imv|mpv|pavucontrol|nm-connection-editor)$" },

    float = true,
})

-- 图片查看器默认大窗
hl.window_rule({
    name  = "imv-size",
    match = { class = "^(imv)$" },

    size = "1000 700",
})

-- rofi 不要动画
hl.layer_rule({
    name  = "rofi-no-anim",
    match = { namespace = "^rofi$" },

    no_anim = true,
})

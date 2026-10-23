local terminal = "kitty"
local fileManager = "kitty -e yazi"
local browser = "firefox"
local codeEditor = "kitty -e nvim"
local monitor = "kitty -e btop"
local launcher = "rofi -show drun -show-icons"
local winSwitcher = "rofi -show window -show-icons"
local clipboard = "cliphist list | rofi -dmenu -display-columns 2 -p clipboard | cliphist decode | wl-copy"

hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = 1.6,
})

hl.on("hyprland.start", function()
	hl.exec_cmd("fcitx5 -d")
	hl.exec_cmd("waybar")
	hl.exec_cmd("mako")
	hl.exec_cmd("hyprpaper")
	hl.exec_cmd("hypridle")
	hl.exec_cmd("wl-paste --watch cliphist store")
	hl.exec_cmd("wl-paste --primary --watch cliphist store")
end)

local mod = "SUPER"

hl.bind(mod .. " + Return", hl.dsp.exec_cmd(terminal), { description = "终端" })
hl.bind(mod .. " + Q", hl.dsp.window.close(), { description = "关窗" })
hl.bind(mod .. " + SHIFT + Q", hl.dsp.window.kill(), { description = "强杀" })
hl.bind(mod .. " + D", hl.dsp.exec_cmd(launcher), { description = "启动器" })
hl.bind(mod .. " + Tab", hl.dsp.exec_cmd(winSwitcher), { description = "窗口切换" })
hl.bind(mod .. " + E", hl.dsp.exec_cmd(fileManager), { description = "文件管理" })
hl.bind(mod .. " + W", hl.dsp.exec_cmd(browser), { description = "浏览器" })
hl.bind(mod .. " + C", hl.dsp.exec_cmd(codeEditor), { description = "编辑器" })
hl.bind(mod .. " + B", hl.dsp.exec_cmd(monitor), { description = "btop" })
hl.bind(mod .. " + V", hl.dsp.exec_cmd(clipboard), { description = "剪贴板" })

hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }), { description = "全屏" })
hl.bind(
	mod .. " + M",
	hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }),
	{ description = "最大化" }
)
hl.bind(mod .. " + Space", hl.dsp.window.float({ action = "toggle" }), { description = "浮动" })
hl.bind(mod .. " + P", hl.dsp.window.pseudo(), { description = "伪平铺" })
hl.bind(mod .. " + T", hl.dsp.layout("togglesplit"), { description = "切分割" })
hl.bind(mod .. " + grave", hl.dsp.window.cycle_next(), { description = "循环窗口" })

for i = 1, 4 do
	local arrow = { "Left", "Right", "Up", "Down" }
	local vim = { "h", "l", "k", "j" }
	local dir = { "l", "r", "u", "d" }
	local dx = { -50, 50, 0, 0 }
	local dy = { 0, 0, -50, 50 }

	hl.bind(mod .. " + " .. arrow[i], hl.dsp.focus({ direction = dir[i] }), { description = "聚焦" })
	hl.bind(mod .. " + " .. vim[i], hl.dsp.focus({ direction = dir[i] }), { description = "聚焦" })

	hl.bind(
		mod .. " + CTRL + " .. arrow[i],
		hl.dsp.window.move({ direction = dir[i] }),
		{ description = "移动窗口" }
	)
	hl.bind(mod .. " + CTRL + " .. vim[i], hl.dsp.window.move({ direction = dir[i] }), { description = "移动窗口" })

	hl.bind(
		mod .. " + ALT + " .. arrow[i],
		hl.dsp.window.swap({ direction = dir[i] }),
		{ description = "交换窗口" }
	)
	hl.bind(mod .. " + ALT + " .. vim[i], hl.dsp.window.swap({ direction = dir[i] }), { description = "交换窗口" })

	hl.bind(
		mod .. " + SHIFT + " .. arrow[i],
		hl.dsp.window.resize({ x = dx[i], y = dy[i], relative = true }),
		{ description = "缩放窗口" }
	)
	hl.bind(
		mod .. " + SHIFT + " .. vim[i],
		hl.dsp.window.resize({ x = dx[i], y = dy[i], relative = true }),
		{ description = "缩放窗口" }
	)
end

for i = 1, 10 do
	local key = i % 10
	hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }), { description = "工作区" .. i })
	hl.bind(
		mod .. " + SHIFT + " .. key,
		hl.dsp.window.move({ workspace = i, follow = true }),
		{ description = "送窗口到" .. i }
	)
end

hl.bind(mod .. " + bracketleft", hl.dsp.focus({ workspace = "e-1" }), { description = "上一个工作区" })
hl.bind(mod .. " + bracketright", hl.dsp.focus({ workspace = "e+1" }), { description = "下一个工作区" })
hl.bind(mod .. " + S", hl.dsp.workspace.toggle_special("magic"), { description = "暂存区" })
hl.bind(
	mod .. " + ALT + S",
	hl.dsp.window.move({ workspace = "special:magic", follow = false }),
	{ description = "送窗口进暂存区" }
)

hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind(mod .. " + L", hl.dsp.exec_cmd("hyprlock"), { description = "锁屏" })
hl.bind("Print", hl.dsp.exec_cmd("grim - | wl-copy"), { locked = true, description = "全屏截图" })
hl.bind(
	mod .. " + SHIFT + S",
	hl.dsp.exec_cmd([[grim -g "$(slurp)" - | wl-copy]]),
	{ locked = true, description = "选区截图" }
)

hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

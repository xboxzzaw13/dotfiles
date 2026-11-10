-- Run from nixos/: lua scripts/check-keybindings.lua [--write]
-- Executes config with inert dispatchers, never launches a program.
-- This checks bindings, not Hyprland's runtime API or a NixOS build.
local allowed = {
    ["exec_cmd"] = true, ["focus"] = true, ["layout"] = true,
    ["window.close"] = true, ["window.kill"] = true,
    ["window.fullscreen"] = true, ["window.float"] = true,
    ["window.pseudo"] = true, ["window.cycle_next"] = true,
    ["window.move"] = true, ["window.swap"] = true,
    ["window.resize"] = true, ["window.drag"] = true,
    ["workspace.toggle_special"] = true,
}
local function dispatcher(path)
    return setmetatable({}, {
        __index = function(_, key)
            local name = path == "" and key or path .. "." .. key
            if name == "window" or name == "workspace" then return dispatcher(name) end
            assert(allowed[name], "Unaudited dispatcher: " .. name)
            return function(value) return { name = name, value = value } end
        end,
    })
end
local seen, registered, count = {}, {}, 0
hl = {
    dsp = dispatcher(""),
    monitor = function(_) end,
    config = function(_) end,
    bind = function(key, action, options)
        local parts = {}
        for part in key:upper():gmatch("[^ +]+") do parts[#parts + 1] = part end
        table.sort(parts)
        local canonical = table.concat(parts, "+")
        assert(not seen[canonical], "Duplicate binding: " .. key)
        seen[canonical] = true
        assert(type(action) == "table" and allowed[action.name], "Unknown action")
        assert(options.description and options.description ~= "", "Missing description")
        if action.name == "exec_cmd" and action.value:match("desktop%-screenshot") then
            assert(not options.locked, "Screenshot must not be available while locked")
        end
        if key:match("Mute$") then assert(not options.repeating, "Repeating mute toggle") end
        registered[key] = true
        count = count + 1
    end,
}
local bindings = dofile("config/wm/hypr/hyprland.lua")
dofile("hosts/Ac0-Nomad/hyprland.lua")
assert(#bindings == count, "Undocumented binding")
local doc = {
    "# Hyprland 快捷键\n",
    "由 `lua scripts/check-keybindings.lua --write` 从实际 Lua 配置生成。Super 是 Windows 键。方向键与 h/j/k/l 均可使用；主键不区分大小写。\n",
    "除媒体/音量/亮度键外，锁屏时禁用桌面快捷键。Ctrl+Alt+F2 切换维护 TTY（系统功能），Ctrl+Space 是 fcitx5 默认输入法切换键。注销可在终端执行 `uwsm stop`，请先保存工作。\n",
    "| 快捷键 | 作用 | 应用/实际命令 | 场景 |",
    "| --- | --- | --- | --- |",
}
local function escape(s) return (tostring(s):gsub("|", "\\|")) end
for _, row in ipairs(bindings) do
    assert(registered[row[1]], "Documented binding not registered")
    for i = 1, 4 do assert(row[i] and row[i] ~= "", "Incomplete documentation") end
    doc[#doc + 1] = "| " .. escape(row[1]) .. " | " .. escape(row[2]) .. " | `" .. escape(row[3]) .. "` | " .. escape(row[4]) .. " |"
end
local generated = table.concat(doc, "\n") .. "\n"
if arg[1] == "--write" then
    local file = assert(io.open("KEYBINDINGS.md", "w"))
    file:write(generated)
    file:close()
else
    local file = assert(io.open("KEYBINDINGS.md", "r"))
    assert(file:read("*a") == generated, "KEYBINDINGS.md is stale; run with --write")
    file:close()
end
print("Checked " .. count .. " unique bindings and documentation (static only).")

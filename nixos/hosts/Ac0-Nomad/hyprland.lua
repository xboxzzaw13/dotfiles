-- Verify the connector with `hyprctl monitors all` in BIOS Hybrid mode.
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1.6 })
-- External displays use the shared auto rule; dGPU-connected outputs prevent RTD3.

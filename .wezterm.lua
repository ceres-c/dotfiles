-- Pull in the wezterm API
local wezterm = require 'wezterm'
local act = wezterm.action

-- This will hold the configuration.
local config = wezterm.config_builder()

-- Font settings
config.font_size = 15
config.font = wezterm.font 'SauceCodePro NF'
config.color_scheme = 'Breeze'

-- Key bindings
config.keys = {
  -- This will create a new split and run your default program inside it
  {
    key = 'o',
    mods = 'SUPER|SHIFT',
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  {
    key = 'e',
    mods = 'SUPER|SHIFT',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  -- Move between panes
  {
    key = 'UpArrow',
    mods = 'CMD',
    action = wezterm.action.ActivatePaneDirection 'Up',
  },
  {
    key = 'DownArrow',
    mods = 'CMD',
    action = wezterm.action.ActivatePaneDirection 'Down',
  },
  {
    key = 'LeftArrow',
    mods = 'CMD',
    action = wezterm.action.ActivatePaneDirection 'Left',
  },
  {
    key = 'RightArrow',
    mods = 'CMD',
    action = wezterm.action.ActivatePaneDirection 'Right',
  },
  -- Resize panes
  {
    key = 'LeftArrow',
    mods = 'CMD|SHIFT',
    action = act.AdjustPaneSize { 'Left', 1 },
  },
  {
    key = 'RightArrow',
    mods = 'CMD|SHIFT',
    action = act.AdjustPaneSize { 'Right', 1 },
  },
  {
    key = 'UpArrow',
    mods = 'CMD|SHIFT',
    action = act.AdjustPaneSize { 'Up', 1 },
  },
  {
    key = 'DownArrow',
    mods = 'CMD|SHIFT',
    action = act.AdjustPaneSize { 'Down', 1 },
  },
  -- Nano key bindings
  { key = 'LeftArrow', mods = 'OPT', action = act.SendString '\x1bb' },
  { key = 'RightArrow', mods = 'OPT', action = act.SendString '\x1bf' },
}

-- Finally, return the configuration to wezterm:
return config

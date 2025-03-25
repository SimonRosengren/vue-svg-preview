-- Main module for the Vue SVG Preview plugin
-- This file serves as the entry point for the plugin

local M = {}

-- Setup function to initialize the plugin with user configuration
function M.setup(opts)
  opts = opts or {}
  
  -- Apply default options
  local defaults = {
    auto_preview = true,       -- Automatically preview SVGs in Vue files
    preview_delay = 100,       -- Delay before showing preview (ms)
    ascii_max_width = 40,      -- Maximum width for ASCII art preview
    ascii_max_height = 20,     -- Maximum height for ASCII art preview
    use_browser = false,       -- Use external browser for SVG preview
    browser_command = nil,     -- Custom browser command (nil for system default)
    temp_file_path = "/tmp",   -- Directory to store temporary SVG files
    use_terminal_graphics = true, -- Try to use terminal graphics protocols
    graphics_implementation = "auto", -- "auto", "kitty", "sixel", or "none"
    max_height = 300,          -- Maximum height for terminal graphics
    max_width = 300,           -- Maximum width for terminal graphics
    conversion_timeout = 2000, -- Timeout for SVG conversion in ms
  }
  
  -- Merge user options with defaults
  for k, v in pairs(defaults) do
    if opts[k] == nil then
      opts[k] = v
    end
  end
  
  -- Store options globally for the plugin
  M.options = opts
  
  -- Load the plugin components
  require('vue-svg-preview.detector')
  
  return M
end

return M

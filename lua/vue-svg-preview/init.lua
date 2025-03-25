-- Main module for the Vue SVG Preview plugin
-- This file serves as the entry point for the plugin

local M = {}

-- Setup function to initialize the plugin with user configuration
function M.setup(opts)
  opts = opts or {}
  
  -- Apply default options
  local defaults = {
    auto_preview = true,       -- Automatically preview SVGs in Vue files
    browser_preview = true,    -- Open preview in browser
    preview_delay = 100,       -- Delay before showing preview (ms)
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

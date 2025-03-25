-- Vue SVG Preview Plugin
-- Main plugin file that sets up autocommands and commands

local M = {}

-- Set up autocommands to detect Vue files with SVG content
vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
  pattern = "*.vue",
  callback = function()
    -- Defer the check to ensure the buffer is fully loaded
    vim.defer_fn(function()
      require('vue-svg-preview.detector').check_for_svg()
    end, 100)
  end,
})

-- Create a command to manually trigger the preview
vim.api.nvim_create_user_command('VueSvgPreview', function()
  require('vue-svg-preview.detector').check_for_svg(true)
end, {})

return M

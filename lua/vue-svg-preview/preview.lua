-- SVG Preview Module
-- Handles the display of SVG content in a floating window

local M = {}

-- Store the window and buffer IDs for the preview
local preview_win = nil
local preview_buf = nil

-- Show SVG preview in a floating window
function M.show_preview(svg_content)
  -- Close existing preview if it exists
  M.close_preview()
  
  -- Create a new buffer for the preview
  preview_buf = vim.api.nvim_create_buf(false, true)
  
  -- Set buffer content with the SVG and some HTML wrapper
  local html_content = {
    "<!DOCTYPE html>",
    "<html>",
    "<head>",
    "  <style>",
    "    body { display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background: #333; }",
    "    svg { max-width: 90%; max-height: 90%; }",
    "  </style>",
    "</head>",
    "<body>",
    "  " .. (svg_content or "No SVG content found"),
    "</body>",
    "</html>"
  }
  
  vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, html_content)
  
  -- Calculate window size (40% of editor size)
  local width = math.floor(vim.o.columns * 0.4)
  local height = math.floor(vim.o.lines * 0.4)
  
  -- Calculate window position (centered)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)
  
  -- Create the floating window
  preview_win = vim.api.nvim_open_win(preview_buf, false, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = "SVG Preview",
    title_pos = "center"
  })
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(preview_buf, "modifiable", false)
  vim.api.nvim_buf_set_option(preview_buf, "bufhidden", "wipe")
  
  -- Set window options
  vim.api.nvim_win_set_option(preview_win, "winblend", 10)
  
  -- Save the preview content to a temporary file and open it in a browser
  M.open_in_browser(html_content)
  
  -- Set up autocmd to close the preview when leaving the buffer
  vim.api.nvim_create_autocmd({"BufLeave", "BufWinLeave"}, {
    buffer = vim.api.nvim_get_current_buf(),
    callback = function()
      M.close_preview()
    end,
    once = true
  })
  
  -- Add keymapping to close the preview
  vim.api.nvim_buf_set_keymap(preview_buf, 'n', 'q', '', {
    callback = function() M.close_preview() end,
    noremap = true,
    silent = true
  })
end

-- Close the preview window if it exists
function M.close_preview()
  if preview_win and vim.api.nvim_win_is_valid(preview_win) then
    vim.api.nvim_win_close(preview_win, true)
    preview_win = nil
  end
  
  if preview_buf and vim.api.nvim_buf_is_valid(preview_buf) then
    vim.api.nvim_buf_delete(preview_buf, { force = true })
    preview_buf = nil
  end
end

-- Open the SVG in a browser for better rendering
function M.open_in_browser(html_content)
  -- Create a temporary file
  local temp_file = os.tmpname() .. ".html"
  
  -- Write the HTML content to the file
  local file = io.open(temp_file, "w")
  if file then
    file:write(table.concat(html_content, "\n"))
    file:close()
    
    -- Open the file in the default browser
    local os_name = vim.loop.os_uname().sysname
    local cmd
    
    if os_name == "Darwin" then  -- macOS
      cmd = "open " .. temp_file
    elseif os_name == "Linux" then
      cmd = "xdg-open " .. temp_file
    elseif os_name:match("Windows") then
      cmd = "start " .. temp_file
    end
    
    if cmd then
      -- Run the command asynchronously
      vim.fn.jobstart(cmd)
      
      -- Schedule cleanup of the temporary file
      vim.defer_fn(function()
        os.remove(temp_file)
      end, 5000)  -- Remove after 5 seconds
    end
  end
end

return M

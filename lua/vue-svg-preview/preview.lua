-- SVG Preview Module
-- Handles the display of SVG content in a floating window

local M = {}

-- Store the window and buffer IDs for the preview
local preview_win = nil
local preview_buf = nil

-- Convert SVG to ASCII art for in-editor preview
function M.svg_to_ascii(svg_content)
  if not svg_content then
    return {"No SVG content found"}
  end
  
  -- Extract width and height from SVG if available
  local width = svg_content:match('width="([^"]+)"') or "24"
  local height = svg_content:match('height="([^"]+)"') or "24"
  
  -- Remove units if present
  width = width:gsub("px", ""):gsub("em", ""):gsub("rem", "")
  height = height:gsub("px", ""):gsub("em", ""):gsub("rem", "")
  
  -- Convert to numbers
  width = tonumber(width) or 24
  height = tonumber(height) or 24
  
  -- Scale to reasonable size for ASCII art (max 40x20)
  local scale_factor = math.min(40 / width, 20 / height)
  local ascii_width = math.floor(width * scale_factor)
  local ascii_height = math.floor(height * scale_factor)
  
  -- Create a simple ASCII representation
  local ascii_art = {}
  
  -- Add header with dimensions
  table.insert(ascii_art, "SVG Icon Preview (" .. width .. "x" .. height .. ")")
  table.insert(ascii_art, string.rep("-", ascii_width + 4))
  
  -- Create a simple box representation
  table.insert(ascii_art, "+" .. string.rep("-", ascii_width) .. "+")
  for i = 1, ascii_height do
    table.insert(ascii_art, "|" .. string.rep(" ", ascii_width) .. "|")
  end
  table.insert(ascii_art, "+" .. string.rep("-", ascii_width) .. "+")
  
  -- Add some info about the SVG
  table.insert(ascii_art, "")
  table.insert(ascii_art, "SVG Content Summary:")
  
  -- Check for common SVG elements
  if svg_content:match("<path") then
    table.insert(ascii_art, "- Contains path elements")
  end
  if svg_content:match("<circle") then
    table.insert(ascii_art, "- Contains circle elements")
  end
  if svg_content:match("<rect") then
    table.insert(ascii_art, "- Contains rectangle elements")
  end
  if svg_content:match("<polygon") then
    table.insert(ascii_art, "- Contains polygon elements")
  end
  if svg_content:match("<g") then
    table.insert(ascii_art, "- Contains group elements")
  end
  
  -- Add footer
  table.insert(ascii_art, "")
  table.insert(ascii_art, "Press 'q' to close this preview")
  
  return ascii_art
end

-- Show SVG preview in a floating window
function M.show_preview(svg_content)
  -- Close existing preview if it exists
  M.close_preview()
  
  -- Create a new buffer for the preview
  preview_buf = vim.api.nvim_create_buf(false, true)
  
  -- Convert SVG to ASCII art for preview
  local ascii_preview = M.svg_to_ascii(svg_content)
  
  -- Set buffer content with the ASCII preview
  vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, ascii_preview)
  
  -- Calculate window size based on content
  local width = 0
  for _, line in ipairs(ascii_preview) do
    width = math.max(width, #line)
  end
  width = math.min(width + 4, vim.o.columns - 10)  -- Add padding, limit to screen width
  local height = math.min(#ascii_preview + 2, vim.o.lines - 6)  -- Add padding, limit to screen height
  
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

return M

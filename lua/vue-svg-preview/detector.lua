-- SVG Detector Module
-- Responsible for detecting SVG content in Vue files

local M = {}
local preview = require('vue-svg-preview.preview')

-- Check if the current buffer contains SVG content within Vue template tags
function M.check_for_svg(force)
  local bufnr = vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(bufnr)
  
  -- Only process .vue files
  if not filename:match("%.vue$") then
    return
  end
  
  -- Get the content of the current buffer
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local content = table.concat(lines, "\n")
  
  -- Check if the file contains an SVG within template tags
  local svg_content = M.extract_svg(content)
  
  if svg_content or force then
    -- If SVG content is found or preview is forced, show the preview
    preview.show_preview(svg_content or "No SVG content found")
  end
end

-- Extract SVG content from Vue template
function M.extract_svg(content)
  -- Look for SVG within template tags
  local template_content = content:match("<template>%s*(.-)%s*</template>")
  
  if not template_content then
    return nil
  end
  
  -- Check if the template contains an SVG element
  local svg_content = template_content:match("(<svg.-</svg>)")
  
  return svg_content
end

return M

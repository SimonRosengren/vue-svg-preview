-- SVG Preview Module
-- Handles the display of SVG content in a floating window or browser

local M = {}
local terminal_graphics = require('vue-svg-preview.terminal_graphics')

-- Store the window and buffer IDs for the preview
local preview_win = nil
local preview_buf = nil
local temp_files = {}

-- Get options from main module
local function get_options()
  return require('vue-svg-preview').options or {}
end

-- Helper function to open a URL in the default browser
local function open_in_browser(url)
  local opts = get_options()
  local cmd
  
  if opts.browser_command then
    cmd = string.format('%s "%s"', opts.browser_command, url)
  else
    -- Detect OS and use appropriate command
    if vim.fn.has('mac') == 1 then
      cmd = string.format('open "%s"', url)
    elseif vim.fn.has('unix') == 1 then
      cmd = string.format('xdg-open "%s"', url)
    elseif vim.fn.has('win32') == 1 then
      cmd = string.format('start "" "%s"', url)
    else
      vim.notify("Unsupported OS for browser preview", vim.log.levels.ERROR)
      return false
    end
  end
  
  local result = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    vim.notify("Failed to open browser: " .. result, vim.log.levels.ERROR)
    return false
  end
  
  return true
end

-- Create a temporary file with SVG content
local function create_temp_svg_file(svg_content)
  local opts = get_options()
  local temp_dir = opts.temp_file_path or "/tmp"
  
  -- Create a unique filename
  local filename = string.format("%s/vue_svg_preview_%s.svg", 
                                temp_dir, 
                                os.time())
  
  -- Write SVG content to file
  local file = io.open(filename, "w")
  if not file then
    vim.notify("Failed to create temporary SVG file", vim.log.levels.ERROR)
    return nil
  end
  
  file:write(svg_content)
  file:close()
  
  -- Store the filename for cleanup later
  table.insert(temp_files, filename)
  
  return filename
end

-- Clean up temporary files
local function cleanup_temp_files()
  terminal_graphics.cleanup_files(temp_files)
  temp_files = {}
end

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
  
  -- Create a canvas for our ASCII art
  local canvas = {}
  for i = 1, ascii_height do
    canvas[i] = {}
    for j = 1, ascii_width do
      canvas[i][j] = " "
    end
  end
  
  -- Analyze SVG content and draw basic shapes on our ASCII canvas
  -- Draw circles if present
  for cx, cy, r in svg_content:gmatch('circle[^>]-cx="([^"]+)"[^>]-cy="([^"]+)"[^>]-r="([^"]+)"') do
    local center_x = tonumber(cx:gsub("px", "")) or 0
    local center_y = tonumber(cy:gsub("px", "")) or 0
    local radius = tonumber(r:gsub("px", "")) or 0
    
    -- Scale to our ASCII canvas
    center_x = math.floor((center_x / width) * ascii_width)
    center_y = math.floor((center_y / height) * ascii_height)
    radius = math.floor((radius / math.max(width, height)) * math.min(ascii_width, ascii_height) * 0.8)
    
    -- Draw a circle using ASCII
    for y = 1, ascii_height do
      for x = 1, ascii_width do
        local dx = x - center_x
        local dy = y - center_y
        local distance = math.sqrt(dx * dx + dy * dy)
        if math.abs(distance - radius) < 0.5 then
          canvas[y][x] = "o"
        elseif distance < radius then
          -- Fill the inside with a lighter character
          if canvas[y][x] == " " then
            canvas[y][x] = "·"
          end
        end
      end
    end
  end
  
  -- Draw rectangles if present
  for x, y, w, h in svg_content:gmatch('rect[^>]-x="([^"]+)"[^>]-y="([^"]+)"[^>]-width="([^"]+)"[^>]-height="([^"]+)"') do
    local rect_x = tonumber(x:gsub("px", "")) or 0
    local rect_y = tonumber(y:gsub("px", "")) or 0
    local rect_w = tonumber(w:gsub("px", "")) or 0
    local rect_h = tonumber(h:gsub("px", "")) or 0
    
    -- Scale to our ASCII canvas
    local start_x = math.floor((rect_x / width) * ascii_width) + 1
    local start_y = math.floor((rect_y / height) * ascii_height) + 1
    local end_x = math.floor(((rect_x + rect_w) / width) * ascii_width)
    local end_y = math.floor(((rect_y + rect_h) / height) * ascii_height)
    
    -- Ensure we stay within bounds
    start_x = math.max(1, math.min(start_x, ascii_width))
    start_y = math.max(1, math.min(start_y, ascii_height))
    end_x = math.max(1, math.min(end_x, ascii_width))
    end_y = math.max(1, math.min(end_y, ascii_height))
    
    -- Draw the rectangle
    for y = start_y, end_y do
      for x = start_x, end_x do
        if x == start_x or x == end_x or y == start_y or y == end_y then
          canvas[y][x] = "+"
        else
          if canvas[y][x] == " " then
            canvas[y][x] = "#"
          end
        end
      end
    end
  end
  
  -- If we have paths, try to represent them with simple lines
  if svg_content:match("<path") then
    -- Find the center of the canvas
    local center_x = math.floor(ascii_width / 2)
    local center_y = math.floor(ascii_height / 2)
    
    -- Draw a simple representation of a path
    -- This is a very simplified approach - just to show something is there
    for i = 1, ascii_width do
      local y = center_y + math.floor(math.sin(i / ascii_width * math.pi * 2) * (ascii_height / 4))
      if y >= 1 and y <= ascii_height then
        canvas[y][i] = "*"
      end
    end
  end
  
  -- If we have polygons, draw a simple polygon shape
  if svg_content:match("<polygon") then
    -- Find points from the first polygon
    local points_str = svg_content:match('polygon[^>]-points="([^"]+)"')
    if points_str then
      local points = {}
      for x, y in points_str:gmatch("([%d%.]+),([%d%.]+)") do
        local px = tonumber(x) or 0
        local py = tonumber(y) or 0
        
        -- Scale to our ASCII canvas
        px = math.floor((px / width) * ascii_width)
        py = math.floor((py / height) * ascii_height)
        
        -- Ensure we stay within bounds
        px = math.max(1, math.min(px, ascii_width))
        py = math.max(1, math.min(py, ascii_height))
        
        table.insert(points, {x = px, y = py})
      end
      
      -- Connect the points with lines
      for i = 1, #points do
        local p1 = points[i]
        local p2 = points[i % #points + 1]  -- Connect back to the first point
        
        -- Draw a line between p1 and p2 (Bresenham's line algorithm)
        local dx = math.abs(p2.x - p1.x)
        local dy = math.abs(p2.y - p1.y)
        local sx = p1.x < p2.x and 1 or -1
        local sy = p1.y < p2.y and 1 or -1
        local err = dx - dy
        
        local x, y = p1.x, p1.y
        while x ~= p2.x or y ~= p2.y do
          if x >= 1 and x <= ascii_width and y >= 1 and y <= ascii_height then
            canvas[y][x] = "/"
          end
          
          local e2 = 2 * err
          if e2 > -dy then
            err = err - dy
            x = x + sx
          end
          if e2 < dx then
            err = err + dx
            y = y + sy
          end
        end
      end
    end
  end
  
  -- Convert our canvas to ASCII art lines
  local ascii_art = {}
  
  -- Add header with dimensions
  table.insert(ascii_art, "SVG Icon Preview (" .. width .. "x" .. height .. ")")
  table.insert(ascii_art, string.rep("-", ascii_width + 4))
  
  -- Add top border
  table.insert(ascii_art, "+" .. string.rep("-", ascii_width) .. "+")
  
  -- Add the canvas content
  for i = 1, ascii_height do
    local line = "|"
    for j = 1, ascii_width do
      line = line .. canvas[i][j]
    end
    line = line .. "|"
    table.insert(ascii_art, line)
  end
  
  -- Add bottom border
  table.insert(ascii_art, "+" .. string.rep("-", ascii_width) .. "+")
  
  -- Add some info about the SVG
  table.insert(ascii_art, "")
  table.insert(ascii_art, "SVG Content Summary:")
  
  -- Check for common SVG elements
  if svg_content:match("<path") then
    table.insert(ascii_art, "- Contains path elements (shown as sine wave)")
  end
  if svg_content:match("<circle") then
    table.insert(ascii_art, "- Contains circle elements (shown as 'o')")
  end
  if svg_content:match("<rect") then
    table.insert(ascii_art, "- Contains rectangle elements (shown as '+')")
  end
  if svg_content:match("<polygon") then
    table.insert(ascii_art, "- Contains polygon elements (shown as '/')")
  end
  if svg_content:match("<g") then
    table.insert(ascii_art, "- Contains group elements")
  end
  
  -- Add footer
  table.insert(ascii_art, "")
  table.insert(ascii_art, "Press 'q' to close this preview")
  
  return ascii_art
end

-- Show SVG preview using the best available method
function M.show_preview(svg_content)
  -- Close existing preview if it exists
  M.close_preview()
  
  local opts = get_options()
  
  -- If browser preview is enabled, use that
  if opts.use_browser then
    -- Create a temporary SVG file
    local svg_file = create_temp_svg_file(svg_content)
    if svg_file then
      -- Convert to file:// URL
      local url = "file://" .. svg_file
      
      -- Open in browser
      if open_in_browser(url) then
        vim.notify("SVG opened in browser", vim.log.levels.INFO)
        return
      else
        vim.notify("Failed to open browser, trying terminal graphics", vim.log.levels.WARN)
      end
    end
  end
  
  -- Try terminal graphics if not using browser or browser failed
  local graphics_capability = terminal_graphics.detect_capabilities()
  
  if graphics_capability ~= "none" then
    -- Create preview window first
    preview_buf = vim.api.nvim_create_buf(false, true)
    
    -- Set buffer content with loading message
    vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, {"Loading SVG preview...", "", "Please wait..."})
    
    -- Calculate window size
    local width = opts.max_width / 4 + 10  -- Approximate character width
    local height = opts.max_height / 8 + 5  -- Approximate character height
    
    -- Create the floating window
    preview_win = vim.api.nvim_open_win(preview_buf, false, {
      relative = "editor",
      width = width,
      height = height,
      row = math.floor((vim.o.lines - height) / 2),
      col = math.floor((vim.o.columns - width) / 2),
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
    
    -- Convert SVG to PNG
    terminal_graphics.svg_to_png(svg_content, function(png_file)
      if not png_file then
        -- Conversion failed, fall back to ASCII
        vim.notify("Failed to convert SVG, falling back to ASCII preview", vim.log.levels.WARN)
        if preview_win and vim.api.nvim_win_is_valid(preview_win) then
          vim.api.nvim_win_close(preview_win, true)
          preview_win = nil
        end
        if preview_buf and vim.api.nvim_buf_is_valid(preview_buf) then
          vim.api.nvim_buf_delete(preview_buf, { force = true })
          preview_buf = nil
        end
        show_ascii_preview(svg_content)
        return
      end
      
      -- Store the PNG file for cleanup
      table.insert(temp_files, png_file)
      
      -- Make buffer modifiable again
      if preview_buf and vim.api.nvim_buf_is_valid(preview_buf) then
        vim.api.nvim_buf_set_option(preview_buf, "modifiable", true)
        
        -- Clear the buffer
        vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, {})
        
        -- Add empty lines for the image
        local lines = {}
        for i = 1, math.floor(opts.max_height / 16) do
          table.insert(lines, "")
        end
        vim.api.nvim_buf_set_lines(preview_buf, 0, -1, false, lines)
        
        -- Display the image using the appropriate protocol
        local success = false
        if graphics_capability == "kitty" then
          success = terminal_graphics.display_kitty_graphics(png_file, preview_win, preview_buf)
        elseif graphics_capability == "sixel" then
          success = terminal_graphics.display_sixel_graphics(png_file, preview_win, preview_buf)
        end
        
        -- Add a footer
        vim.api.nvim_buf_set_lines(preview_buf, -1, -1, false, {"", "Press 'q' to close this preview"})
        vim.api.nvim_buf_set_option(preview_buf, "modifiable", false)
        
        -- If terminal graphics failed, fall back to ASCII
        if not success then
          vim.notify("Terminal graphics failed, falling back to ASCII preview", vim.log.levels.WARN)
          if preview_win and vim.api.nvim_win_is_valid(preview_win) then
            vim.api.nvim_win_close(preview_win, true)
            preview_win = nil
          end
          if preview_buf and vim.api.nvim_buf_is_valid(preview_buf) then
            vim.api.nvim_buf_delete(preview_buf, { force = true })
            preview_buf = nil
          end
          show_ascii_preview(svg_content)
        else
          -- Add keymapping to close the preview
          vim.api.nvim_buf_set_keymap(preview_buf, 'n', 'q', '', {
            callback = function() M.close_preview() end,
            noremap = true,
            silent = true
          })
          
          -- Set up autocmd to close the preview when leaving the buffer
          vim.api.nvim_create_autocmd({"BufLeave", "BufWinLeave"}, {
            buffer = vim.api.nvim_get_current_buf(),
            callback = function()
              M.close_preview()
            end,
            once = true
          })
        end
      end
    end)
  else
    -- No terminal graphics available, use ASCII preview
    show_ascii_preview(svg_content)
  end
end

-- Show ASCII art preview in a floating window
function show_ascii_preview(svg_content)
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
  
  -- Clean up any temporary files
  cleanup_temp_files()
  
  -- Clear any terminal graphics
  if vim.fn.executable('kitty') == 1 then
    vim.fn.system("kitty +kitten icat --clear --silent")
  end
end

return M

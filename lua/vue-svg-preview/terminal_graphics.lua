-- Terminal Graphics Module
-- Handles displaying SVG content using terminal graphics protocols

local M = {}

-- Get options from main module
local function get_options()
  return require('vue-svg-preview').options or {}
end

-- Detect terminal graphics capabilities
function M.detect_capabilities()
  local opts = get_options()
  
  -- If user disabled terminal graphics, return none
  if not opts.use_terminal_graphics then
    return "none"
  end
  
  -- If user specified a specific implementation, use that
  if opts.graphics_implementation ~= "auto" then
    return opts.graphics_implementation
  end
  
  -- Check for Kitty terminal
  if vim.env.TERM == "xterm-kitty" or 
     vim.env.KITTY_WINDOW_ID or 
     vim.fn.system("ps -p $(ps -p $$ -o ppid=) -o comm="):match("kitty") then
    return "kitty"
  end
  
  -- Check for Alacritty with Kitty protocol support
  if vim.env.ALACRITTY_LOG or vim.fn.system("ps -p $(ps -p $$ -o ppid=) -o comm="):match("alacritty") then
    -- Try to detect if kitty graphics protocol is available in this Alacritty
    local test_file = os.tmpname()
    local cmd = string.format("kitty +kitten icat --silent --transfer-mode=file --place=1x1@0,0 %s 2>/dev/null", test_file)
    local result = vim.fn.system(cmd)
    os.remove(test_file)
    
    if vim.v.shell_error == 0 then
      return "kitty"
    end
  end
  
  -- Check for terminals that support sixel
  if vim.env.TERM:match("sixel") or vim.fn.has("gui_running") == 1 then
    return "sixel"
  end
  
  -- No supported graphics protocol detected
  return "none"
end

-- Check if required conversion tools are available
function M.check_conversion_tools()
  local tools = {}
  
  -- Check for rsvg-convert (librsvg)
  local rsvg_result = vim.fn.system("which rsvg-convert")
  tools.rsvg = (vim.v.shell_error == 0)
  
  -- Check for ImageMagick
  local convert_result = vim.fn.system("which convert")
  tools.imagemagick = (vim.v.shell_error == 0)
  
  -- Check for cairosvg (Python)
  local cairosvg_result = vim.fn.system("which cairosvg")
  tools.cairosvg = (vim.v.shell_error == 0)
  
  return tools
end

-- Convert SVG to PNG using available tools
function M.svg_to_png(svg_content, callback)
  local tools = M.check_conversion_tools()
  local opts = get_options()
  
  -- Create a temporary SVG file
  local temp_svg = os.tmpname() .. ".svg"
  local file = io.open(temp_svg, "w")
  if not file then
    vim.notify("Failed to create temporary SVG file", vim.log.levels.ERROR)
    callback(nil)
    return
  end
  
  file:write(svg_content)
  file:close()
  
  -- Create a temporary PNG file
  local temp_png = temp_svg:gsub("%.svg$", ".png")
  
  -- Try conversion tools in order of preference
  local cmd = nil
  if tools.rsvg then
    cmd = string.format("rsvg-convert -w %d -h %d -o %s %s", 
                        opts.max_width or 300, 
                        opts.max_height or 300, 
                        temp_png, temp_svg)
  elseif tools.imagemagick then
    cmd = string.format("convert -resize %dx%d %s %s", 
                        opts.max_width or 300, 
                        opts.max_height or 300, 
                        temp_svg, temp_png)
  elseif tools.cairosvg then
    cmd = string.format("cairosvg -f png -W %d -H %d %s -o %s", 
                        opts.max_width or 300, 
                        opts.max_height or 300, 
                        temp_svg, temp_png)
  else
    vim.notify("No SVG conversion tools found", vim.log.levels.ERROR)
    os.remove(temp_svg)
    callback(nil)
    return
  end
  
  -- Run the conversion command with a timeout
  local timeout = opts.conversion_timeout or 2000
  local job_id = vim.fn.jobstart(cmd, {
    on_exit = function(_, code)
      os.remove(temp_svg)
      if code == 0 then
        callback(temp_png)
      else
        vim.notify("SVG conversion failed", vim.log.levels.ERROR)
        if vim.fn.filereadable(temp_png) == 1 then
          os.remove(temp_png)
        end
        callback(nil)
      end
    end
  })
  
  -- Set up timeout
  vim.defer_fn(function()
    if vim.fn.jobwait({job_id}, 0)[1] == -1 then
      vim.fn.jobstop(job_id)
      vim.notify("SVG conversion timed out", vim.log.levels.ERROR)
      os.remove(temp_svg)
      if vim.fn.filereadable(temp_png) == 1 then
        os.remove(temp_png)
      end
      callback(nil)
    end
  end, timeout)
end

-- Display image using Kitty graphics protocol
function M.display_kitty_graphics(image_path, win_id, buf_id)
  local opts = get_options()
  
  -- Get window dimensions
  local win_width = vim.api.nvim_win_get_width(win_id)
  local win_height = vim.api.nvim_win_get_height(win_id)
  
  -- Calculate image placement
  local place_width = math.min(opts.max_width, win_width - 4)
  local place_height = math.min(opts.max_height, win_height * 8) -- Approximate terminal cell height
  
  -- Build the kitty graphics command
  local cmd = string.format(
    "kitty +kitten icat --silent --transfer-mode=file " ..
    "--align=center --place=%dx%d@%d,%d %s",
    place_width, place_height,
    2, 2,  -- position (add some padding)
    image_path
  )
  
  -- Execute the kitty graphics command
  local job_id = vim.fn.jobstart(cmd, {
    on_exit = function(_, code)
      if code ~= 0 then
        vim.notify("Failed to display image with Kitty protocol", vim.log.levels.ERROR)
        return false
      end
    end
  })
  
  return true
end

-- Display image using Sixel graphics protocol
function M.display_sixel_graphics(image_path, win_id, buf_id)
  -- Implementation for sixel would go here
  -- This is more complex and requires additional tools
  vim.notify("Sixel graphics not yet implemented", vim.log.levels.WARN)
  return false
end

-- Clean up temporary files
function M.cleanup_files(files)
  for _, file in ipairs(files) do
    if file and vim.fn.filereadable(file) == 1 then
      os.remove(file)
    end
  end
end

return M

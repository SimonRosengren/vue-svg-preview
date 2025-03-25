# Vue SVG Preview

A Neovim plugin that automatically detects and previews SVG content in Vue files directly within Neovim.

## Features

- Automatically detects SVG content in Vue files
- Shows a preview of the SVG in one of three ways:
  - As actual SVG graphics in terminals that support it (default)
  - As ASCII art in a floating window inside Neovim (fallback)
  - In your default browser for actual SVG rendering (optional)
- Provides information about SVG elements and dimensions
- Provides a command to manually trigger the preview

## Installation

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'simonrosengren/vue-svg-preview',
  config = function()
    require('vue-svg-preview').setup()
  end
}
```

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
return {
  'simonrosengren/vue-svg-preview',
  config = function()
    require('vue-svg-preview').setup()
  end
}
```

## Configuration

The plugin works out of the box, but you can customize it:

```lua
require('vue-svg-preview').setup({
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
})
```

## Usage

- Open a Vue file containing an SVG within template tags
- The plugin will automatically detect and preview the SVG:
  - By default, as actual SVG graphics in terminals that support it
  - As ASCII art in terminals without graphics support
  - In your browser if `use_browser = true`
- Use `:VueSvgPreview` to manually trigger the preview
- Press `q` in the preview window to close it

## How It Works

The plugin scans Vue files for SVG content within template tags. When found, it:

### For Terminal Graphics Preview (Default)
1. Detects if your terminal supports graphics protocols (like Kitty's)
2. Converts the SVG to PNG using available tools (rsvg-convert, ImageMagick, or cairosvg)
3. Displays the PNG directly in your terminal using the appropriate protocol
4. Falls back to ASCII art if any step fails

### For ASCII Preview (Fallback)
1. Extracts the SVG dimensions and elements
2. Creates an ASCII art representation of the SVG
3. Displays information about the SVG elements
4. Shows everything in a floating window within Neovim

### For Browser Preview (Optional)
1. Creates a temporary SVG file
2. Opens the file in your default browser (or specified browser)
3. Cleans up the temporary file when you close Neovim

## Requirements

- Neovim 0.5.0+
- For terminal graphics:
  - A terminal that supports graphics protocols (Kitty, Alacritty with kitty graphics protocol)
  - At least one of these SVG conversion tools:
    - `rsvg-convert` (from librsvg package)
    - ImageMagick (`convert` command)
    - cairosvg (Python package)
- A web browser (for browser preview mode)

## License

MIT

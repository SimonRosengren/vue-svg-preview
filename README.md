# Vue SVG Preview

A Neovim plugin that automatically detects and previews SVG content in Vue files directly within Neovim.

## Features

- Automatically detects SVG content in Vue files
- Shows a preview of the SVG as ASCII art in a floating window inside Neovim
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
})
```

## Usage

- Open a Vue file containing an SVG within template tags
- The plugin will automatically detect and preview the SVG as ASCII art
- Use `:VueSvgPreview` to manually trigger the preview
- Press `q` in the preview window to close it

## How It Works

The plugin scans Vue files for SVG content within template tags. When found, it:
1. Extracts the SVG dimensions and elements
2. Creates an ASCII art representation of the SVG
3. Displays information about the SVG elements
4. Shows everything in a floating window within Neovim

## Requirements

- Neovim 0.5.0+

## License

MIT

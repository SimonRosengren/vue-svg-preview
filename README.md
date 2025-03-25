# Vue SVG Preview

A Neovim plugin that automatically detects and previews SVG content in Vue files.

## Features

- Automatically detects SVG content in Vue files
- Shows a preview of the SVG in a floating window
- Opens the SVG in your default browser for better rendering
- Provides a command to manually trigger the preview

## Installation

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'yourusername/vue-svg-preview',
  config = function()
    require('vue-svg-preview').setup()
  end
}
```

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'yourusername/vue-svg-preview',
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
  browser_preview = true,    -- Open preview in browser
  preview_delay = 100,       -- Delay before showing preview (ms)
})
```

## Usage

- Open a Vue file containing an SVG within template tags
- The plugin will automatically detect and preview the SVG
- Use `:VueSvgPreview` to manually trigger the preview
- Press `q` in the preview window to close it

## Requirements

- Neovim 0.5.0+
- A modern browser for external previews

## License

MIT

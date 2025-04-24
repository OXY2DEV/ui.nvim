# 💻 ui.nvim

A blueprint/template/guide to customize Neovim's UI using Lua.

## ✨ Features

- Custom UI for the command-line. It supports,
    - Block mode(with context lines too).
    - Icons based on command-line state.
    - Titles.
    - Concealing text(for `:lua`, `:=` etc.).
    - `VimResized` support.
    - Changing appearance based on command-line state.
    - Syntax highlighting(tree-sitter based).

- Custom UI for the message. It supports,
	- Ignoring specific messages.
    - Changing message content and highlighting.
    - Separate window(s) for `confirmation` and `list` style messages.
    - Custom `:messages` window.

- Custom UI for the pop-up menu. It supports,
	- Icons for different entry types.
    - Changing how each entry is shown(padding, background, select color).

- Dynamic highlight groups.

## 🤦‍♂️ Known issues

- Pum menu giving incorrect position & size in completion events.
  Breaks: `mini.completion`

## 📥 Installation

### 💤 lazy.nvim

>[!WARNING]
> Do not lazy load this plugin! It is supposed to be loaded before other plugins(right after loading your `colorscheme`).

For `plugins.lua` users,

```lua
{
    "OXY2DEV/ui.nvim",
    lazy = false
};
```

For `plugins/ui.lua` users,

```lua
return {
    "OXY2DEV/ui.nvim",
    lazy = false
};
```

### 🦠 Mini.deps

```lua
local MiniDeps = require("mini.deps");

MiniDeps.add({
    source = "OXY2DEV/ui.nvim"
});
```

<!-- ### 🌒 Rocks.nvim -->
<!---->
<!-- >[!WARNING] -->
<!-- > `luarocks package` may sometimes be a bit behind `main`. -->
<!---->
<!-- ```vim -->
<!-- :Rocks install ui.nvim -->
<!-- ``` -->

## 🔩 Configuration

The plugin can be configured via the `setup()` function.

>[!TIP]
> You can call the `setup()` as many times as you want!

## 📚 Guide

The [wiki](https://github.com/OXY2DEV/ui.nvim/wiki/Configuration) explains how to create your own UIs using lua.

## 💻 Commands

You can run `:UI` to toggle the custom UI. It has the following sub-commands,

- `enable`
  Enables custom UI.

- `disable`
  Disables custom UI.

- `toggle`
  Toggles custom UI.


# 💻 ui.nvim

A minimal command-line & message UI for Neovim.

>[!TIP]
> You can use this repo as a `blueprint` to create your own version of the UI(s).

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
    - Changing message content and highlighting.
    - Separate window(s) for `confirmation` and `list` style messages.
    - Custom `:messages` window.
- Dynamic highlight groups.

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

## 📚 Guide

The [wiki](https://github.com/OXY2DEV/ui.nvim/wiki) explains how to create your own UIs using lua.



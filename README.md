# 💻 ui.nvim

<img src="https://github.com/OXY2DEV/ui.nvim/blob/images/images/ui.nvim.png">
<img src="https://github.com/OXY2DEV/ui.nvim/blob/images/images/ui.nvim-cmdline.png">
<img src="https://github.com/OXY2DEV/ui.nvim/blob/images/images/ui.nvim-messages.png">
<img src="https://github.com/OXY2DEV/ui.nvim/blob/images/images/ui.nvim-popupmenu_cmp.png">

A blueprint/template/guide to customize Neovim's UI using Lua.

<details><!--|fS-->
    <summary>Expand for advanced usage!</summary>

## 🤔 So, what is this?

This is a simple customisable UI plugin written in Lua for you to play around with!

If you ever worked on modifying Neovim's UI, it might feel frustrating to work with. The docs(as of `0.11`) don't go too deep into it either(as this is still **experimental**). This repository is meant to change that.

You no longer need to write `boilerplate` or handle errors without using messages or spend **hours** trying to figure put how to handle different Ui events. As this is also usable as a plugin, you don't have to worry about things being outdated either!

## 📦 What's included?

As of now, this plugin comes with the following things,

- Basic UI event handler(separated into parts for better readability & portability).
- Working example on handling *most* events.
- Type definitions for different events.
- Helpful `heads up` for various *quirky scenarios*.
- Basic state manager for command-line & messages.
- A simple logger for logging messages(WIP).

A bunch of helpers are also provided,

- Dynamic highlight groups(see `ui/highlights.lua`). This automatically makes the plugin supported by *almost* all colorschemes.
- Utility function for showing `virtual text` & `UI contents` into a buffer as **actual text** with highlights!
- Utility function for turning `virtual text` into statuscolumn content. This makes adding complex signs on wrapped lines much easier!
- A basic reading time calculator. This makes long messages stay on the screen for longer durations.
- A basic value evaluator. Useful if you want to support `functions` as configuration options without using `conditionals` everywhere.

## 📜 Where to start?

I recommend reading `:h ui.txt` first(don't worry if you don't understand it).

>[!TIP]
> The wiki is also available in vimdoc(see `:h ui.nvim`)!

You can check the [wiki](https://github.com/OXY2DEV/ui.nvim/wiki) for the explanations and read the source files for the actual implementation.

>[!NOTE]
> If you want to help, feel free to point out issues with the wiki!

</details><!--|fE-->

## ✨ Features

- Custom UI for the command-line. It supports,
    - Block mode support(with context lines too).
    - Changing appearance(background color, filetype etc.) based on command-line state.
    - Custom titles.
    - Concealing text(for `:lua`, `:=`, `:!` etc.).
    - Syntax highlighting(tree-sitter based).

- Custom UI for the message. It supports,
    - Ignoring specific messages.
    - Changing message content and highlighting.
    - Separate window(s) for `confirmation` and `list` style messages.
    - Custom `:messages` window with support for multiple message providers(`vim` & `internal`).
    - `showcmd` support.

- Custom UI for the pop-up menu. It supports,
    - Icons for different entry types.
    - Changing how each entry is shown(padding, background, select color).

- Dynamic highlight groups.

## 🤦‍♂️ Known issues

- Pum menu giving incorrect position & size in completion events(This is a missing feature of Neovim).
  Breaks: `mini.completion`

- In certain `redraw` events, the write message is shown for some reason(pretty sure this is an already reported bug).
  Breaks: `nvim-0.11`

## 📝 Requirements

- Neovim 0.11, though 0.10 also works *for the most part*.

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

### 🌒 Rocks.nvim

>[!WARNING]
> `luarocks package` may sometimes be a bit behind `main`.

```vim
:Rocks install ui.nvim
```

## 🔩 Configuration

The plugin can be configured via the `setup()` function. You can check the default configuration table [here](https://github.com/OXY2DEV/ui.nvim/blob/752ef3a1eb2aa2ffa33efd055f3cbbc6b417b435/lua/ui/spec.lua#L5-L1172).

A simplified version of the configuration table is given below,

```lua
require("ui").setup({
    popupmenu = {
        enable = true,

        winconfig = {},
        tooltip = nil,

        styles = {
            default = {
                padding_left = " ",
                padding_right = " ",

                icon = nil,
                text = nil,

                normal_hl = nil,
                select_hl = "CursorLine",
                icon_hl = nil
            },

            example = {
                condition = function ()
                    return true;
                end,

                icon = "I "
            }
        }
    },

    cmdline = {
        enable = true,

        styles = {
            default = {
                cursor = "Cursor",
                filetype = "vim",

                icon = { { "I ", "@comment" } },
                offset = 0,

                title = nil,
                winhl = ""
            },

            example = {
                condition = function ()
                    return true;
                end,

                cursor = "@comment"
            }
        }
    },

    message = {
        enable = true,

        message_winconfig = {},
        list_winconfig = {},
        confirm_winconfig = {},
        history_winconfig = {},

        ignore = function ()
            return false:
        end,

        showcmd = {
            max_width = 10,
            modifier = nil
        },

        msg_styles = {
            default = {
                duration = 500,

                modifier = nil,
                decorations = {
                    icon = { { "I " } }
                }
            },

            example = {
                condition = function ()
                    return true;
                end,

                decorations = {
                    icon = { { "B " } }
                }
            }
        },

        is_list = function ()
            return false;
        end,

        list_styles = {
            default = {
                modifier = nil,

                row = nil,
                col = nil,

                width = nil,
                height = nil,

                winhl = nil
            },

            example = {
                condition = function ()
                    return true;
                end,

                border = "rounded"
            }
        },
        confirm_styles = {
            default = {
                modifier = nil,

                row = nil,
                col = nil,

                width = nil,
                height = nil,

                winhl = nil
            },

            example = {
                condition = function ()
                    return true;
                end,

                border = "rounded"
            }
        }
    }
});
```

>[!TIP]
> You can call the `setup()` as many times as you want!

------

The various configurations tables are given below. You can find them in `spec.default` [here](https://github.com/OXY2DEV/ui.nvim/blob/main/lua/ui/spec.lua).

### ✨ Command-line

Command-line styles can be found in `spec.default.cmdline.styles`. These are,

- `__keymap`, used for showing keys & actions in confirmation messages.
- `search_up`, used for `/`.
- `search_down`, used for `?`.
- `set`, used for `:set`.
- `shell`, used for `:!`.
- `substitute`, used for `:s/`, `:%s/`, `:1,2s/` etc.
- `lua_eval`, used for `:=`.
- `lua`, used for `:lua`.
- `prompt`, used when a prompt is shown.

### ✨ Message

Message styles can be found in `spec.default.message.msg_styles`. These are,

- `__swap`, Used for the swapfile exists error.
- `__spell`, Used when adding new entries to the spell file(e.g. `zg`).
- `__lua_error`, Used for error messages in Lua.
- `option`, Used for the output of `:set <option>?`, this sometimes picks up normal messages too.
- `search`, Used for showing searched word,
- `error_msg`, Used for regular error messages(fallback for `__lua_error`).
- `highlight_link`, Used for output of `:hi <group>` that uses `link`.
- `highlight_group`, Used for output of `:hi <group>`.
- `write`, Used for the message shown when writing to a file.
- `undo_redo`, Used for `undo` & `redo` messages.

#### Confirm messages

Confirm message styles can be found in `spec.default.message.confirm_styles`. These are,

- `swap_alert`, Used when showing the `swapfile exists` error.
- `write_confirm`, Used when writing a read-only file.

#### List messages

List message styles can be found in `spec.default.message.list_styles`. These are,

- `ls`, Used for the buffer list.
- `hi`, Used for the output of `:hi`.

### ✨ Pop-up menu

Pop-up menu item styles can be found in `spec.default.popupmenu.styles`. These are,

- `buffer_variable`, Used for buffer local variables(`b:*`).
- `global_variable`, Used for global variables(`g:*`).
- `local_variable`, Used by `l:*`, `a:*` & `s:*`.
- `tabpage_variable`, Used for tabpage local variables(`t:*`).
- `vim_variable`, Used for Vim variables(`v:`).
- `window_variable`, Used for window local variables(`w:`).
- `class`, Used for items whose kind is `m`.
- `function`, Self-explanatory.
- `macro`, Used for items whose kind is `d`.
- `type_definition`, Used for items whose kind is `t`.
- `variable`, Used for items whose kind is `v`.

## 💻 Commands

You can run `:UI` to toggle the custom UI. It has the following sub-commands,

- `enable`
  Enables custom UI.

- `disable`
  Disables custom UI.

- `toggle`
  Toggles custom UI.

- `clear`
  Clears all visible messages.

## 🎨 Highlight groups

By default this plugin comes with the following highlight groups,

- `UICmdlineDefault`
- `UICmdlineDefaultIcon`
- `UICmdlineLua`
- `UICmdlineLuaIcon`
- `UICmdlineEval`
- `UICmdlineEvalIcon`
- `UICmdlineSearchUp`
- `UICmdlineSearchUpIcon`
- `UICmdlineSearchDown`
- `UICmdlineSearchDownIcon`
- `UICmdlineSubstitute`
- `UICmdlineSubstituteIcon`

- `UIMessageDefault`
- `UIMessageOk`
- `UIMessageInfo`
- `UIMessageInfoSign`
- `UIMessageWarn`
- `UIMessageWarnSign`
- `UIMessageError`
- `UIMessageErrorSign`
- `UIMessagePalette`
- `UIMessageErrorSign`

- `UIHistoryKeymap`
- `UIHistoryDesc`
- `UIMenuSelect`
- `UIMenuKeymap`



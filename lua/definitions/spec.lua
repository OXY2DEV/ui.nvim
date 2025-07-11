---@meta

---@class ui.config
---
---@field popupmenu? ui.config.popupmenu
---@field cmdline? ui.config.cmdline
---@field message? ui.config.message


---@class ui.config.popupmenu Configuration for the completion popup menu.
---
---@field enable? boolean Should this module be enabled?
---@field tooltip? [ string, string? ][] | fun(): [ string, string? ][] Tooltip(as virtual text)
---
---@field winconfig? table | fun(state: ui.popupmenu.state, position?: "top_left" | "top_right" | "bottom_left" | "bottom_right"): table Window configuration for the pop-up menu.
---@field max_height? integer Maximum height of the completion menu.
---
---@field styles? table<string, ui.popupmenu.style> Styles for the completion items.


---@class ui.config.popupmenu__static Static configuration for the completion popup menu.
---
---@field enable? boolean Should this module be enabled?
---@field tooltip? [ string, string? ][] Tooltip(as virtual text)
---
---@field winconfig? table Window configuration for the pop-up menu.
---@field max_height? integer Maximum height of the completion menu.
---
---@field styles table<string, ui.popupmenu.style__static>


---@class ui.config.cmdline Configuration for the command-line.
---
---@field enable? boolean Should this module be enabled?
---@field row_offset? integer Row offset for the command-line.
---@field styles? table<string, ui.cmdline.style> Styles for the cmdline


---@class ui.config.cmdline__static Configuration for the command-line.
---
---@field enable? boolean Should this module be enabled?
---@field row_offset? integer Row offset for the command-line.
---@field styles? table<string, ui.cmdline.style__static> Styles for the cmdline


---@class ui.config.message
---
---@field enable? boolean Should this module be enabled?
---@field wrap_notify? boolean Wrap `vim.notify()` & `vim.notify_once()`?
---@field respect_replace_last? boolean Should `replace_last` be respected?
---
---@field history_preference? ui.message.source History preference for :messages
---@field history_types? ui.message.visible_types History message level.
---@field max_lines? integer Maximum number of lines a normal message can have.
---@field max_duration? integer Maximum number of milliseconds a message can be visible for.
---
---@field message_winconfig? table Window configuration for the message window.
---@field list_winconfig? table Window configuration for the list message window.
---@field confirm_winconfig? table Window configuration for the confirmation window.
---@field history_winconfig? table Window configuration for the history window.
---@field showcmd_winconfig? table Window configuration for the showcmd window.
---
---@field is_list? fun(kind: ui.message.kind, content: ui.message.fragment[], add_to_history: boolean): (boolean, boolean) Is `msg` a list-type message?
---@field ignore? fun(kind: ui.message.kind, content: ui.message.fragment[]): boolean Should this message be ignored?
---
---@field showcmd? ui.message.showcmd Showcmd options.
---@field msg_styles? table<string, ui.message.style> Message styles.
---@field confirm_styles? table<string, ui.message.confirm> Confirmation message style.
---@field list_styles? table<string, ui.message.list> List message style.

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
---@field max_height? integer Maximum height of the completion menu.
---
---@field entries table<string, ui.popupmenu.style> Styles for the completion items.


---@class ui.config.popupmenu__static Static configuration for the completion popup menu.
---
---@field enable? boolean Should this module be enabled?
---@field tooltip? [ string, string? ][] Tooltip(as virtual text)
---@field entries table<string, ui.popupmenu.style__static>


---@class ui.config.cmdline Configuration for the command-line.
---
---@field enable? boolean Should this module be enabled?
---@field styles? table<string, ui.cmdline.style> Styles for the cmdline


---@class ui.config.cmdline__static Configuration for the command-line.
---
---@field enable? boolean Should this module be enabled?
---@field styles? table<string, ui.cmdline.style__static> Styles for the cmdline



---@class ui.config.message
---
---@field enable? boolean Should this module be enabled?
---
---@field message_winconfig? table Window configuration for the message window.
---@field list_winconfig? table Window configuration for the list message window.
---@field confirm_winconfig? table Window configuration for the confirmation window.
---@field history_winconfig? table Window configuration for the history window.
---
---@field is_list fun(msg: ui.message.entry): boolean Is `msg` a list-type message?
---@field is_list fun(kind: ui.message.kind, content: ui.message.fragment[]): boolean Should this message be ignored?
---
---@field processors? table<string, ui.message.processor> Message processors.
---@field confirm? table<string, ui.message.confirm> Confirmation message style.
---@field list? table<string, ui.message.list> List message style.

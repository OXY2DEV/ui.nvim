--- Type definition for the `message` module.
--- Maintainer: MD. Mouinul Hossain
---@meta


---@class ui.message.style Message pstyle
---
---@field condition? fun(msg: ui.message.entry, lines: string[], extmarks: ui.message.extmarks): boolean Condition for this processor.
---
---@field duration? integer | fun(msg: ui.message.entry, lines: string[], extmarks: ui.message.extmarks): integer Message visibility duration(in milliseconds).
---@field modifier? ui.message.modified | fun(msg: ui.message.entry, lines: string[], extmarks: ui.message.extmarks): ui.message.modified Modified version of the message.
---@field decorations? ui.message.decorations | fun(msg: ui.message.entry, lines: string[], extmarks: ui.message.extmarks): ui.message.decorations Decorations for the message.
---@field history_decorations? ui.message.decorations | fun(msg: ui.message.entry, lines: string[], extmarks: ui.message.extmarks): ui.message.decorations Decorations for the message in history.


---@class ui.message.style__static Static message style.
---
---@field condition? boolean Condition for this processor.
---
---@field duration? integer Message visibility duration(in milliseconds).
---@field modifier? ui.message.modified Modified version of the message.
---@field decorations? ui.message.decorations Decorations for the message.
---@field history_decorations? ui.message.decorations Decorations for the message in history.


---@class ui.message.modified Modified version of a message
---
---@field lines? string[] Line of text a message for the message.
---@field extmarks? ui.message.extmarks Highlight for the lines of the message.


---@class ui.message.decorations Decorations for the message.
---
---@field from? integer Start line index for the message(0-indexed), Set by the plugin.
---@field to? integer End line index for the message(0-indexed), Set by the plugin.
---
---@field icon? [ string, string? ][] Virtual text used as icon for the message.
---@field padding? [ string, string? ][] Virtual text used as padding for the lines of the message(excluding the start/end line).
---@field tail? [ string, string? ][] Virtual text for the last line.
---
---@field line_hl_group? string


---@alias ui.message.extmarks
---| {} Used when getting message duration
---| ( ui.message.hl_fragment[] )[] Used when rendering messages.


---@alias ui.message.border
---| "rounded"
---| "solid"
---| "single"
---| "double"
---| string[]
---| [ string, string? ][]


---@class ui.message.confirm Style for the confirmation window.
---
---@field condition? fun(msg: ui.message.entry, lines: string[], extmarks: ui.message.extmarks): boolean Condition for this confirm message.
---
---@field border? ui.message.border | fun(msg: ui.message.entry, lines: string[], extmarks: ui.message.extmarks): ui.message.border Confirmation window border.
---
---@field row? integer | fun(msg: ui.message.entry, lines: string[], extmarks: ui.message.extmarks): integer Row position of the confirmation window.
---@field col? integer | fun(msg: ui.message.entry, lines: string[], extmarks: ui.message.extmarks): integer Column position of the confirmation window.
---
---@field width? integer | fun(msg: ui.message.entry, lines: string[], extmarks: ui.message.extmarks): integer Width of the confirmation window.
---@field height? integer | fun(msg: ui.message.entry, lines: string[], extmarks: ui.message.extmarks): integer Width of the confirmation window.
---
---@field modifier? ui.message.modified | fun(msg: ui.message.entry, lines: string[], extmarks: ui.message.extmarks): ui.message.modified Modified version of the message.
---@field winhl? string | fun(msg: ui.message.entry, lines: string[], extmarks: ui.message.extmarks): string Value of 'winhl' for the confirmation window.


---@class ui.message.confirm__static Static style for the confirmation window.
---
---@field condition? boolean Condition for this confirm message.
---
---@field border? ui.message.border Confirmation window border.
---
---@field row? integer Row position of the confirmation window.
---@field col? integer Column position of the confirmation window.
---
---@field width? integer Width of the confirmation window.
---@field height? integer Width of the confirmation window.
---
---@field modifier? ui.message.modified Modified version of the message.
---@field winhl? string Value of 'winhl' for the confirmation window.


---@class ui.message.list Style for the list window.
---
---@field condition? fun(msg: ui.message.entry, lines: string[], extmarks: ui.message.extmarks): boolean Condition for this list message.
---
---@field border? ui.message.border | fun(msg: ui.message.entry, lines: string[], extmarks: ui.message.extmarks): ui.message.border List window border.
---
---@field row? integer | fun(msg: ui.message.entry, lines: string[], extmarks: ui.message.extmarks): integer Row position of the list window.
---@field col? integer | fun(msg: ui.message.entry, lines: string[], extmarks: ui.message.extmarks): integer Column position of the list window.
---
---@field width? integer | fun(msg: ui.message.entry, lines: string[], extmarks: ui.message.extmarks): integer Width of the list window.
---@field height? integer | fun(msg: ui.message.entry, lines: string[], extmarks: ui.message.extmarks): integer Width of the list window.
---
---@field modifier? ui.message.modified | fun(msg: ui.message.entry, lines: string[], extmarks: ui.message.extmarks): ui.message.modified Modified version of the message.
---@field winhl? string | fun(msg: ui.message.entry, lines: string[], extmarks: ui.message.extmarks): string Value of 'winhl' for the list window.


---@class ui.message.list__static Static style for the list window.
---
---@field condition? boolean Condition for this list message.
---
---@field border? ui.message.border Confirmation window border.
---
---@field row? integer Row position of the list window.
---@field col? integer Column position of the list window.
---
---@field width? integer Width of the list window.
---@field height? integer Width of the list window.
---
---@field modifier? ui.message.modified Modified version of the message.
---@field winhl? string Value of 'winhl' for the list window.


--- Different types of messages.
---@alias ui.message.kind
---| ""
---| "bufwrite"
---| "confirm"
---| "emsg"
---| "echo"
---| "echomsg"
---| "echoerr"
---| "completion"
---| "list_cmd"
---| "lua_error"
---| "lua_print"
---| "lua_print"
---| "rpc_error"
---| "return_prompt"
---| "quickfix"
---| "search_cmd"
---| "search_count"
---| "shell_err"
---| "shell_out"
---| "shell_ret"
---| "undo"
---| "verbose"
---| "wildlist"
---| "wmsg"


---@class ui.message.fragment A fragment of a message.
---
---@field [1] integer Attribute ID(unused).
---@field [2] string Message chunk.
---@field [3] integer Highlight group ID(Used for coloring).


---@class ui.message.entry A message entry.
---
---@field kind ui.message.kind
---@field content ui.message.fragment[]
---
---@field timer? table Timer for message visibility, not available in history.


---@class ui.message.hl_fragment A highlight group entry for the messages.
---
---@field [1] integer Start byte index of the highlight group.
---@field [2] integer End byte index of the highlight group.
---@field [3] string Name of the highlight group


---@class ui.message.showcmd
---
---@field max_width? integer Maximum width of the showcmd window.
---@field modifier? fun(content: ui.message.fragment[][], lines: string[], extmarks: ui.message.hl_fragment[][]): ui.message.modified Modified version of the showcmd.

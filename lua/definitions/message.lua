--- Type definition for the `message` module.
--- Maintainer: MD. Mouinul Hossain
---@meta

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


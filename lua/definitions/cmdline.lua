--- Type definition for the `command-line` module.
--- Maintainer: MD. Mouinul Hossain

--- Configuration table for the command-line.
---@class ui.cmdline.configuration
---
---@field styles table<string, ui.cmdline.style>


--- Style for the command-line.
---@class ui.cmdline.style
---
---@field condition? fun(state: ui.cmdline.state): boolean Condition for this style(`nil` for the default style).
---@field cursor? string Highlight group for the cursor in the command-line.
---@field filetype? string File type for the command-line buffer.
---@field icon? [ string, string? ][] Icon shown on the left side of the command-line. Same structure as virtual text.
---@field offset? integer Number of characters to hide from the start(used for `:lua`, `:=`).
---@field title? ( [ string, string? ][] )[] Title for the command-line. Same structure as virtual lines.
---@field winhl? string Value of 'winhl' for the command-line window.


--- State of the command-line.
---@class ui.cmdline.state
---
---@field pos integer Cursor position.
---@field firstc "?" | "/" | ":" | "=" Command-line type.
---@field prompt? string Prompt text.
---@field indent integer Indentation of the text.
---@field level integer Level of the command-line.
---@field hl_id? integer Highlight group ID for `prompt`.


---@alias ui.cmdline.lines string[] Lines of text shown in the command-line.
---@alias ui.cmdline.decorations ( ui.cmdline.decoration[] )[] Decorations for the command-line.


--- Line count for various parts of the cmdline.
---@class ui.cmdline.line_stat
---
---@field [1] integer Number of lines in the title.
---@field [2] integer Number of lines as context.
---@field [3] integer Number of lines used by the command-line.


--- Internal representation of highlighting in messages.
--- E.g. `{ { 128, "Some text" }, ... }` => `{ { { 0, 9, "Normal" } } }`
---@class ui.cmdline.decoration
---
---@field [1] integer Start byte.
---@field [2] integer End byte.
---@field [3] string Highlight group name.


---@alias ui.cmdline.content ( [ integer, string ][] )[] Content for the command-line.


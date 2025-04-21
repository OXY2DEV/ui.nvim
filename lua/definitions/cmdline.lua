--- Type definition for the `command-line` module.
--- Maintainer: MD. Mouinul Hossain
---@meta


---@class ui.cmdline.configuration Configuration table for the command-line.
---
---@field styles table<string, ui.cmdline.style>


---@class ui.cmdline.configuration__static Static configuration table for the command-line.
---
---@field styles table<string, ui.cmdline.style__static>


--- Style for the command-line.
---@class ui.cmdline.style
---
---@field condition? fun(state: ui.cmdline.state, lines: string[]): boolean Condition for this style(`nil` for the default style).
---@field cursor? string | fun(state: ui.cmdline.state, lines: string[]): string Highlight group for the cursor in the command-line.
---@field filetype? string | fun(state: ui.cmdline.state, lines: string[]): string File type for the command-line buffer.
---@field icon? [ string, string? ][] | fun(state: ui.cmdline.state, lines: string[]): [ string, string? ][] Icon shown on the left side of the command-line. Same structure as virtual text.
---@field offset? integer | fun(state: ui.cmdline.state, lines: string[]): integer Number of characters to hide from the start(used for `:lua`, `:=`).
---@field title? ( [ string, string? ][] )[] | fun(state: ui.cmdline.state, lines: string[]): ( [ string, string? ][] )[] Title for the command-line. Same structure as virtual lines.
---@field winhl? string | fun(state: ui.cmdline.state, lines: string[]): string Value of 'winhl' for the command-line window.


---@class ui.cmdline.style__static Static style for the command-line.
---
---@field condition? boolean Condition for this style(`nil` for the default style).
---
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
---@field lines? ui.cmdline.content[] Context lines.


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


---@meta


---@class ui.popupmenu.state State of the popup menu.
---
---@field items ui.popupmenu.item[] Completion items.
---@field selected integer | -1 Selected item's index(0-indexed).
---
---@field row integer Anchor position(in row).
---@field col integer Anchor position(in column).
---
---@field grid integer Grid ID.


---@class ui.popupmenu.item A completion item for the popup menu.
---
---@field [1] string Completion text.
---@field [2] ui.popupmenu.kind | ""
---@field [3] string Completion menu.
---@field [4] string Extra information.


---@alias ui.popupmenu.kind "v" | "f" | "m" | "t" | "d"


---@class ui.popupmenu.style Style for popup menu entry.
---
---@field condition? fun(word: string, kind: ui.popupmenu.kind, memu: string, info: string): boolean Condition for this style.
---
---@field padding_left? string | fun(word: string, kind: ui.popupmenu.kind, memu: string, info: string): string
---@field icon? string | fun(word: string, kind: ui.popupmenu.kind, memu: string, info: string): string
---@field text? string | fun(word: string, kind: ui.popupmenu.kind, memu: string, info: string): string
---@field padding_right? string | fun(word: string, kind: ui.popupmenu.kind, memu: string, info: string): string
---
---@field icon_hl? string | fun(word: string, kind: ui.popupmenu.kind, memu: string, info: string): string
---@field normal_hl? string | fun(word: string, kind: ui.popupmenu.kind, memu: string, info: string): string
---@field select_hl? string | fun(word: string, kind: ui.popupmenu.kind, memu: string, info: string): string Highlight group when this item gets selected.


---@class ui.popupmenu.style__static Static style for popup menu entry.
---
---@field condition? boolean Condition for this style.
---
---@field padding_left? string
---@field icon? string
---@field text? string
---@field padding_right? string
---
---@field icon_hl? string
---@field normal_hl? string
---@field select_hl? string Highlight group when this item gets selected.



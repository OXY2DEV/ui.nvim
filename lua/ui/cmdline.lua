--- Custom command-line for
--- Neovim.
local cmdline = {};
local log = require("ui.log");

------------------------------------------------------------------------------

cmdline.state = {};

cmdline.get_state = function (key, fallback)
	return cmdline.state[key] or fallback;
end

cmdline.set_state = function (state)
	cmdline.state = vim.tbl_extend("force", cmdline.state, state);
end

------------------------------------------------------------------------------

---@type integer Command-line namespace.
cmdline.namespace = vim.api.nvim_create_namespace("ui.cmdline");

---@type integer Namespace for the cursor in command-line.
cmdline.cursor_ns = vim.api.nvim_create_namespace("ui.cmdline.cursor");

--- Cmdline buffer & window.
---@type integer, integer
cmdline.buffer, cmdline.window = nil, nil;

------------------------------------------------------------------------------

cmdline.__prepare = function ()
	--- Temporarily disable 'cursorline'.
	if not vim.g.__ui_cursorline then
		vim.g.__ui_cursorline = vim.o.cursorline == true;
		vim.o.cursorline = false;
	end

	--- Create command-line buffer.
	if not cmdline.buffer or vim.api.nvim_buf_is_valid(cmdline.buffer) == false then
		cmdline.buffer = vim.api.nvim_create_buf(false, true);
	end

end

cmdline.__render = function ()
	cmdline.__prepare();
end

------------------------------------------------------------------------------

--- Cmdline draw event
---@param content [ string[], string ][]
---@param pos integer
---@param firstc string
---@param prompt string
---@param indent integer
---@param level integer
cmdline.cmdline_show = function (content, pos, firstc, prompt, indent, level)
	cmdline.set_state({
		content = content,
		pos = pos,
		firstc = firstc,
		prompt = prompt,
		indent = indent,
		level = level
	});

	table.insert(log.entries, vim.inspect(cmdline.state));
	-- cmdline.__update_ui();
end

--- Handles command-line events.
---@param event string
---@param ... any
cmdline.handle = function (event, ...)
	local _, err = pcall(cmdline[event], ...);
	table.insert(log.entries, string.format("Received: %s", event));
end

return cmdline;

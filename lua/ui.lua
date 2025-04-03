--- Example UI module
--- for Neovim.
local ui = {};

--- Maps event names to modules.
---@type table<string, "cmdline" | "linegrid" | "message">
ui.event_map = {
	grid_resize = "linegrid",
	default_colors_set = "linegrid",
	hl_attr_define = "linegrid",
	hl_group_set = "linegrid",
	grid_line = "linegrid",
	grid_clear = "linegrid",
	grid_destroy = "linegrid",
	grid_cursor_goto = "linegrid",
	grid_scroll = "linegrid",

	cmdline_show = "cmdline",
	cmdline_pos = "cmdline",
	cmdline_hide = "cmdline",
	cmdline_special_char = "cmdline",
	cmdline_block_show = "cmdline",
	cmdline_block_append = "cmdline",
	cmdline_block_hide = "cmdline",

	msg_show = "message",
	msg_clear = "message",
	msg_showmode = "message",
	msg_showcmd = "message",
	msg_ruler = "message",
	msg_history_show = "message",
	msg_history_clear = "message"
};

---@type boolean
ui.enabled = false;

---@type integer
ui.namespace = vim.api.nvim_create_namespace("ui");

--- Attaches to UI listener.
ui.attach = function ()
	ui.enabled = true;

	---@type table<string, table>
	local modules = {
		cmdline = require("ui.cmdline"),
		linegrid = require("ui.linegrid"),
		message = require("ui.message"),
	};

	vim.ui_attach(ui.namespace, {
		ext_cmdline = true,
		ext_messages = true,
		-- ext_linegrid = true
	}, function (event, ...)
		local mod_name = ui.event_map[event];
		if not mod_name then return; end

		---@type boolean, string?
		local success, err = pcall(modules[mod_name].handle, event, ...);
	end);
end

--- Detaches from UI listener.
ui.detach = function ()
	ui.enabled = false;
	vim.ui_detach(ui.namespace);
end

ui.setup = function ()
	ui.attach();
end

return ui;

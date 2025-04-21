--- Example UI module
--- for Neovim.
local ui = {};
local log = require('ui.log');

--- Maps event names to modules.
---@type table<string, "cmdline" | "linegrid" | "message" | "popup">
ui.event_map = {
	---|fS

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
	msg_history_clear = "message",

	popupmenu_show = "popup",
	popupmenu_select = "popup",
	popupmenu_hide = "popup",

	---|fE
};

---@type boolean
ui.enabled = false;

---@type integer
ui.namespace = vim.api.nvim_create_namespace("ui");

--- Attaches to UI listener.
ui.attach = function ()
	---|fS

	local spec = require("ui.spec");
	ui.enabled = true;

	---@type table<string, table>
	local modules = {
		cmdline = require("ui.cmdline"),
		linegrid = require("ui.linegrid"),
		message = require("ui.message"),
		popup = require("ui.popup"),
	};

	log.print("Setting up UI modules,");
	log.level_inc();

	for k, v in pairs(modules) do
		log.print("Module: " .. k);
		log.assert(
			pcall(v["setup"])
		);
	end

	log.level_dec();

	vim.ui_attach(ui.namespace, {
		ext_cmdline = true,
		ext_messages = true,

		ext_popupmenu = spec.config.popupmenu.enable == true,
	}, function (event, ...)
		log.print("Event, " .. event);
		log.level_inc();

		local mod_name = ui.event_map[event];
		if not mod_name then return; end

		---@type boolean, string?
		log.assert(
			pcall(modules[mod_name].handle, event, ...)
		)

		log.level_dec();
	end);

	---|fE
end

--- Detaches from UI listener.
ui.detach = function ()
	ui.enabled = false;
	vim.ui_detach(ui.namespace);
end

---@param config ui.config
ui.setup = function (config)
	---|fS

	if config then
		local spec = require("ui.spec");
		spec.config = vim.tbl_deep_extend("force", spec.config, config);
	end

	ui.attach();

	---|fE
end

return ui;

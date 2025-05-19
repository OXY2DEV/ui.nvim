--- Example UI module
--- for Neovim.
local ui = {};
local log = require("ui.log");

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

	log.print("Setting up UI modules,", "ui.lua");
	log.level_inc();

	for k, v in pairs(modules) do
		log.print("Module: " .. k, "ui.lua", "log");
		log.level_inc();

		log.assert(
			"ui.lua → setup()",
			pcall(v["setup"])
		);

		log.assert(
			"ui.lua → on_attach()",
			pcall(v["on_attach"])
		);

		log.level_dec();
	end

	log.level_dec();

	vim.ui_attach(ui.namespace, {
		ext_cmdline = (spec.config.cmdline.enable == true or spec.config.message.enable == true) and true or false,
		ext_messages = spec.config.message.enable == true,

		ext_popupmenu = spec.config.popupmenu.enable == true,
	}, function (event, ...) ---@diagnostic disable-line
		log.print("Event: " .. event, "ui.lua", "log");
		log.level_inc();

		local mod_name = ui.event_map[event];
		if not mod_name then return; end

		---@type boolean, string?
		log.assert(
			"ui.lua",
			pcall(modules[mod_name].handle, event, ...)
		)

		log.level_dec();
	end);

	-- BUG, when run from the cmdline, the cmdline
	-- stays visible. So we manually hide the cmdline
	-- window.
	vim.schedule(function ()
		pcall(modules.cmdline.cmdline_hide);
	end);

	---|fE
end

--- Detaches from UI listener.
ui.detach = function ()
	---|fS

	ui.enabled = false;
	vim.ui_detach(ui.namespace);

	---@type table<string, table>
	local modules = {
		cmdline = require("ui.cmdline"),
		linegrid = require("ui.linegrid"),
		message = require("ui.message"),
		popup = require("ui.popup"),
	};

	log.print("Detaching from modulez,", "ui.lua");
	log.level_inc();

	for k, v in pairs(modules) do
		log.print("Module: " .. k, "ui.lua", "log");
		log.level_inc();

		log.assert(
			"ui.lua → on_detach()",
			pcall(v["on_detach"])
		);

		log.level_dec();
	end

	log.level_dec();
	modules.message.__showcmd({});

	---|fE
end

ui.actions = {
	attach = ui.attach,
	detach = ui.detach,

	toggle = function ()
		if ui.enabled == false then
			ui.actions.attach();
		else
			ui.actions.detach();
		end
	end,

	log = function ()
		require("ui.log").export(nil, true);
	end,

	clear = function ()
		local message = require("ui.message");

		for k, v in pairs(message.visible) do
			v.timer:stop();
			message.__remove(k);
		end

		message.__render();
	end
};

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

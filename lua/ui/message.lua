--- Custom message for
--- Neovim.
local message = {};

local log = require("ui.log");
local spec = require("ui.spec");
local utils = require("ui.utils");

------------------------------------------------------------------------------

---@class ui.message
---
---@field namespace integer
---@field current_order integer Current messages order.
---
---@field buffer? integer
---@field window? integer
---
---@field confirm_buffer? integer
---@field confirm_window? integer
---
---@field list_buffer? integer
---@field list_window? integer
---
---@field showmode_buffer? integer
---@field showmode_window? integer
---
---@field history_buffer? integer
---@field history_window? integer
message.data = {
	namespace = vim.api.nvim_create_namespace("ui.message"),

	buffer = nil,
	window = nil,

	confirm_buffer = nil,
	confirm_window = nil,

	list_buffer = nil,
	list_window = nil,

	showmode_buffer = nil,
	showmode_window = nil,

	history_buffer = nil,
	history_window = nil,
};

---@type ui.message.entry[]
message.history = {};

---@type ui.message.entry[]
message.visible = {};

---@type table<string, ui.message.entry>
message.visible_special = {};

---@type ui.message.decorations[]
message.statuscolumn_decorations = {}

message.timer = function (id, duration, interval)
	local timer = vim.uv.new_timer();

	if timer then
		timer:start(duration, interval, vim.schedule_wrap(function ()
			message.free(id);
		end));
	end

	return timer;
end

message.free = function (id)
	if type(id) == "string" then
		message.visible_special[id] = nil;
	else
		message.visible[id] = nil;
	end

	vim.schedule(function ()
		log.assert(
			"ui/message.lua → remove_render",
			pcall(message.render)
		);
	end);
end

---@param kind ui.message.kind
---@param content ui.message.fragment[]
---@param replace_last boolean
---@param history boolean
---@param _append boolean
---@param id string
---@param _trigger string
---@return ui.message.entry
message.new = function (kind, content, replace_last, history, _append, id, _trigger)
	return {
		id = id,
		kind = kind,
		type = "normal",

		content = content,

		replace_last = replace_last,
		add_to_history = history,

		timer = nil,
	} --[[@as ui.message.entry]];
end

------------------------------------------------------------------------------

message.msg_show = function (kind, content, replace_last, history, append, id, trigger)
	vim.schedule(function ()
		local msg = message.new(kind, content, replace_last, history, append, id, trigger);
		local lines = utils.to_lines(content);
		local style = spec.get_msg_style(msg, lines, {}) or {};

		-- NOTE: Make sure to reset the freeing timer.
		if message.visible_special[id] then
			message.visible_special[id].timer:stop();
		elseif message.visible[id] then
			message.visible[id].timer:stop();
		end

		msg.timer = message.timer(id, style.duration or 5000);

		if type(id) == "string" then
			message.visible_special[id] = msg;
		else
			message.visible[id] = msg;
		end
		message.history[id] = msg;

		log.assert(
			"ui/message.lua → add_render",
			pcall(message.render)
		);
	end)
end

------------------------------------------------------------------------------

message.set_buf_win = function (buf, win)
	---@type vim.api.keyset.win_config
	local window_opts = {
		relative = "editor",

		row = 0, col = 0,
		width = 1, height = 1,

		border = "none",
		style = "minimal",

		hide = true, focusable = false
	};

	if not message.data[buf] or not vim.api.nvim_buf_is_valid(message.data[buf]) then
		message.data[buf] = vim.api.nvim_create_buf(false, true);
	end

	if not message.data[win] or not vim.api.nvim_win_is_valid(message.data[win]) then
		message.data[win] = vim.api.nvim_open_win(message.data[buf], false, window_opts);
		vim.api.nvim_win_set_var(message.data[win], "ui_window", true);

		utils.set("w", message.data[win], "foldmethod", "manual");
		utils.set("w", message.data[win], "numberwidth", 1);
	end
end

message.prepare = function ()
	message.set_buf_win("buffer", "window");
	message.set_buf_win("confirm_buffer", "confirm_window");
	message.set_buf_win("list_buffer", "list_window");
	message.set_buf_win("history_buffer", "history_window");
	message.set_buf_win("showmode_buffer", "showmode_window");
end

message.render = function ()
	---|fS

	message.prepare();

	local lines = {};
	local extmarks = {};

	-- Visible messages
	local msg_orders = vim.tbl_keys(message.visible);
	local sp_msg_orders = vim.tbl_keys(message.visible_special);

	if #msg_orders == 0 and #sp_msg_orders == 0 then
		vim.api.nvim_win_close(message.data.window, true);
		return;
	end

	table.sort(msg_orders);

	for _, msg_order in ipairs(msg_orders) do
		local msg = message.visible[msg_order];
		local m_lines, m_exts = utils.process_content(msg.content);

		local style = spec.get_msg_style(msg, m_lines, m_exts) or {};
		if style.modifier then
			m_lines = style.modifier.lines or m_lines;
			m_exts = style.modifier.extmarks or m_exts;
		end

		lines = vim.list_extend(lines, m_lines);
		extmarks = vim.list_extend(extmarks, m_exts);
	end

	table.sort(sp_msg_orders);

	for _, msg_order in ipairs(sp_msg_orders) do
		local msg = message.visible_special[msg_order];
		local m_lines, m_exts = utils.process_content(msg.content);

		local style = spec.get_msg_style(msg, m_lines, m_exts) or {};
		if style.modifier then
			m_lines = style.modifier.lines or m_lines;
			m_exts = style.modifier.extmarks or m_exts;
		end

		lines = vim.list_extend(lines, m_lines);
		extmarks = vim.list_extend(extmarks, m_exts);
	end

	while lines[#lines] == "" do
		table.remove(lines);
	end

	vim.api.nvim_buf_clear_namespace(message.data.buffer, message.data.namespace, 0, -1);
	vim.api.nvim_buf_set_lines(message.data.buffer, 0, -1, false, lines);

	local width = math.min(
		math.floor(vim.o.columns * 0.5),
		utils.max_len(lines)
	);
	local height = utils.wrapped_height(lines, width);

	local window_opts = vim.tbl_extend("force", spec.config.message.message_winconfig, {
		relative = "editor",
		anchor = "SE",

		row = vim.o.lines - 1,
		col = vim.o.columns,

		width = width,
		height = height,

		border = "none",

		zindex = 200,
		hide = false,
	});

	vim.api.nvim_win_set_config(message.data.window, window_opts);
	utils.redraw({
		flush = true,
		statuscolumn = true,

		win = message.data.window
	}, {
		ignore = false,
	});

	---|fE
end

--- Handles message events.
---@param event string
---@param ... any
message.handle = function (event, ...)
	---|fS

	log.level_inc();

	log.assert(
		"ui/message.lua",
		pcall(message[event], ...)
	);

	log.level_dec();
	log.print(vim.inspect({ ... }), "ui/message.lua", "debug");

	---|fE
end

message.setup = function ()
	---|fS

	vim.api.nvim_create_autocmd("VimResized", {
		callback = function ()
			-- message.__list_resize();
			--
			-- if vim.g.__ui_showcmd then
			-- 	message.__showcmd(vim.g.__ui_showcmd);
			-- end

			message.render();
		end
	});
	--
	-- vim.api.nvim_create_autocmd("TabLeave", {
	-- 	callback = function ()
	-- 		pcall(vim.api.nvim_win_close, message.msg_window, true);
	-- 		pcall(vim.api.nvim_win_close, message.show_window, true);
	--
	-- 		message.msg_window = nil;
	-- 		message.show_window = nil;
	-- 	end
	-- });
	--
	-- vim.api.nvim_create_autocmd({
	-- 	"VimEnter",
	-- 	"TabEnter"
	-- }, {
	-- 	callback = function ()
	-- 		message.__render();
	-- 	end
	-- });

	---|fE
end

return message;

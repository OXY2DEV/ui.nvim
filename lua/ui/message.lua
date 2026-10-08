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
message.visible_decorations = {};

---@type ui.message.decorations[]
message.statuscolumn_decorations = {}

message.timer = function (id, duration, interval)
	local timer = vim.uv.new_timer();

	if timer then
		timer:start(duration or 5000, interval or 0, vim.schedule_wrap(function ()
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

local movement_keys = {
	vim.api.nvim_replace_termcodes("<left>", true, true, true),
	vim.api.nvim_replace_termcodes("<down>", true, true, true),
	vim.api.nvim_replace_termcodes("<up>", true, true, true),
	vim.api.nvim_replace_termcodes("<right>", true, true, true),

	vim.api.nvim_replace_termcodes("h", true, true, true),
	vim.api.nvim_replace_termcodes("j", true, true, true),
	vim.api.nvim_replace_termcodes("k", true, true, true),
	vim.api.nvim_replace_termcodes("l", true, true, true),
};

message.confirm_movement = function (key)
	---|fS

	local success, pos = pcall(vim.api.nvim_win_get_cursor, message.data.confirm_window);
	if not success then return; end

	if key == movement_keys[1] or key == movement_keys[5] then
		pos[1] = math.max(0, pos[1] - 1);
	elseif key == movement_keys[2] or key == movement_keys[6] then
		pos[2] = math.max(0, pos[2] - 1);
	elseif key == movement_keys[3] or key == movement_keys[7] then
		pos[2] = pos[2] + 1;
	elseif key == movement_keys[4] or key == movement_keys[8] then
		pos[1] = pos[1] + 1;
	end

	pcall(vim.api.nvim_win_set_cursor, message.data.confirm_window, pos);

	---|fE
end

---@param kind ui.message.kind
---@param content ui.message.fragment[]
---@param replace_last boolean
---@param history boolean
---@param append boolean
---@param id string
---@param trigger string
message.msg_confirm = function (kind, content, replace_last, history, append, id, trigger)
	---|fS

	local msg = message.new(kind, content, replace_last, history, append, id, trigger);
	vim.g.__ui_confirm_msg = msg;

	message.history[id] = msg;
	message.prepare();

	local lines, extmarks = utils.process_content(content);
	local style = spec.get_confirm_style(msg, lines, extmarks);

	if style.modifier then
		lines = style.modifier.lines or lines;
		extmarks = style.modifier.extmarks or extmarks;
	end

	vim.api.nvim_buf_clear_namespace(message.data.confirm_buffer, message.data.namespace, 0, -1);
	vim.api.nvim_buf_set_lines(message.data.confirm_buffer, 0, -1, false, lines);
	message.apply_extmarks("msg_confirm", message.data.confirm_buffer, extmarks);

	local width = math.min(
		math.floor(vim.o.columns * 0.5),
		utils.max_len(lines)
	);
	local height = utils.wrapped_height(lines, width);

	local window_opts = vim.tbl_extend("force", spec.config.message.confirm_winconfig or {}, {
		relative = "editor",

		row = style.row or math.ceil((vim.o.lines - height) / 2),
		col = style.col or math.ceil((vim.o.columns - width) / 2),

		width = width,
		height = height,

		border = "none",

		zindex = 200,
		hide = false,
	});

	vim.api.nvim_win_set_config(message.data.confirm_window, window_opts);
	vim.api.nvim_set_current_win(message.data.confirm_window);

	utils.redraw({
		flush = true,
		statuscolumn = true,

		win = message.data.confirm_window
	}, {
		ignore = false,
	});

	vim.on_key(function (key)
		if not vim.list_contains(vim.g.__confirm_keys or {}, string.lower(key)) then
			if vim.list_contains(movement_keys, key) then
				pcall(message.confirm_movement, key);
				pcall(vim.cmd, "mode");
			end

			return;
		end

		pcall(vim.api.nvim_win_close, message.data.confirm_window, true);
		vim.on_key(nil, message.data.namespace);

		vim.g.__ui_confirm_msg = nil;
	end, message.data.namespace)

	---|fE
end

---@param kind ui.message.kind
---@param content ui.message.fragment[]
---@param replace_last boolean
---@param history boolean
---@param append boolean
---@param id string
---@param trigger string
message.msg_list = function (kind, content, replace_last, history, append, id, trigger)
	---|fS

	local msg = message.new(kind, content, replace_last, history, append, id, trigger);
	message.history[id] = msg;
	message.prepare();

	vim.api.nvim_buf_set_keymap(message.data.list_buffer, "n", "q", "", {
		callback = function ()
			pcall(vim.api.nvim_win_close, message.data.list_window, true);
		end
	});

	local lines, extmarks = utils.process_content(content);
	local style = spec.get_listmsg_style(msg, lines, extmarks);

	if style.modifier then
		lines = style.modifier.lines or lines;
		extmarks = style.modifier.extmarks or extmarks;
	end

	vim.api.nvim_buf_clear_namespace(message.data.list_buffer, message.data.namespace, 0, -1);
	vim.api.nvim_buf_set_lines(message.data.list_buffer, 0, -1, false, lines);
	message.apply_extmarks("msg_list", message.data.list_buffer, extmarks);

	local width = math.min(
		math.floor(vim.o.columns * 0.5),
		utils.max_len(lines)
	);
	local height = utils.wrapped_height(lines, width);

	local window_opts = vim.tbl_extend("force", spec.config.message.list_winconfig or {}, {
		relative = "editor",

		row = style.row or math.ceil((vim.o.lines - height) / 2),
		col = style.col or math.ceil((vim.o.columns - width) / 2),

		width = width,
		height = height,

		border = "none",

		zindex = 200,
		hide = false,
	});

	vim.api.nvim_win_set_config(message.data.list_window, window_opts);
	vim.api.nvim_set_current_win(message.data.list_window);

	utils.redraw({
		flush = true,
		statuscolumn = true,

		win = message.data.list_window
	}, {
		ignore = false,
	});

	---|fE
end

---@param kind ui.message.kind
---@param content ui.message.fragment[]
---@param replace_last boolean
---@param history boolean
---@param append boolean
---@param id string
---@param trigger string
message.msg_show = function (kind, content, replace_last, history, append, id, trigger)
	vim.schedule(function ()
		if kind == "confirm" then
			message.msg_confirm(kind, content, replace_last, history, append, id, trigger);
			return;
		end

		local is_list = spec.is_list(kind, content, history);
		local msg = message.new(kind, content, replace_last, history, append, id, trigger);
		local lines = utils.to_lines(content);

		if is_list or #lines > (spec.config.message.max_lines or math.floor(vim.o.lines * 0.5)) then
			message.msg_list(kind, content, replace_last, history, append, id, trigger);
			return;
		end

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

local showmode_hide_timer = vim.uv.new_timer();

message.showmode_hide = function ()
	if not showmode_hide_timer then
		showmode_hide_timer = vim.uv.new_timer();
	end

	if showmode_hide_timer then
		showmode_hide_timer:stop();
		showmode_hide_timer:start(500, 0, vim.schedule_wrap(function ()
			pcall(vim.api.nvim_win_close, message.data.showmode_window, true);
		end));
	end
end

message.showmode_resize = function ()
	---|fS

	if vim.api.nvim_win_is_valid(message.data.showmode_window) then
		---@type vim.api.keyset.win_config
		local window_opts = {
			relative = "editor",
			anchor = "SW",

			row = vim.o.lines - (1 + message.cmdline_offset()),
			col = 0,

			border = "none",

			zindex = 200,
			hide = false,
		};

		vim.api.nvim_win_set_config(message.data.showmode_window, window_opts);
		utils.redraw({
			flush = true,
			win = message.data.showmode_window
		}, {
			ignore = false,
		});
	end

	---|fE
end

message.msg_showcmd = function (content)
	---|fS

	if #content == 0 then
		message.showmode_hide();
		return;
	end

	message.prepare();

	local lines, extmarks = utils.process_content(content);
	local modifier = utils.eval(spec.config.message.showcmd.modifier, content, lines, extmarks);

	if modifier then
		lines = modifier.lines or lines;
		extmarks = modifier.extmarks or extmarks;
	end

	vim.api.nvim_buf_clear_namespace(message.data.showmode_buffer, message.data.namespace, 0, -1);
	vim.api.nvim_buf_set_lines(message.data.showmode_buffer, 0, -1, false, lines);
	message.apply_extmarks("msg_list", message.data.showmode_buffer, extmarks);

	local width = utils.max_len(lines);
	local height = 1;

	---@type vim.api.keyset.win_config
	local window_opts = {
		relative = "editor",
		anchor = "SW",

		row = vim.o.lines - (1 + message.cmdline_offset()),
		col = 0,

		width = width,
		height = height,

		border = "none",

		zindex = 200,
		hide = false,
	};

	vim.api.nvim_win_set_config(message.data.showmode_window, window_opts);
	utils.set("w", message.data.showmode_window, "sidescrolloff", 999)
	pcall(vim.api.nvim_win_set_cursor, message.data.showmode_window, { 0, width })

	utils.redraw({
		flush = true,
		win = message.data.showmode_window
	}, {
		ignore = false,
	});

	---|fE
end

------------------------------------------------------------------------------

message.statuscolumn = function ()
	---|fS

	local win = vim.g.statusline_winid;

	if win ~= message.data.window and win ~= message.data.history_window then
		return "";
	end

	local row = vim.v.lnum - 1;

	for _, item in ipairs(message.visible_decorations) do
		if row >= item.from and row <= item.to then
			if vim.v.virtnum == 0 then
				if row == item.from then
					return "%=" .. utils.to_statuscolumn(item.icon);
				elseif row == item.to then
					return "%=" .. utils.to_statuscolumn(item.tail or item.padding or item.icon);
				else
					return "%=" .. utils.to_statuscolumn(item.padding or item.icon);
				end
			else
				return "%=";
			end

			break;
		end
	end

	return "";

	---|fE
end

_G.ui_statuscolumn = message.statuscolumn;

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

	utils.set("w", message.data.window, "statuscolumn", "%!v:lua.ui_statuscolumn()");
end

message.apply_extmarks = function (src, buffer, extmarks)
	---|fS

	for l, line in ipairs(extmarks) do
		for _, item in ipairs(line) do
			if item[3] == "" then
				goto continue;
			end

			log.assert(
				"ui/message.lua → " .. src,
				pcall(
					vim.api.nvim_buf_set_extmark,
					buffer,
					message.data.namespace,

					l - 1,
					item[1],

					{
						end_col = item[2],
						hl_group = item[3],
					}
				)
			);

			::continue::
		end
	end

	---|fE
end

---@return integer
message.apply_msg_decorations = function ()
	---|fS

	local decor_width = 0;

	for _, item in ipairs(message.visible_decorations) do
		if item.icon then
			decor_width = math.max(decor_width, utils.virt_len(item.icon));
		end

		if item.line_hl_group then
			pcall(vim.api.nvim_buf_set_extmark, message.data.buffer, message.data.namespace, item.from, 0, {
				end_row = item.to,
				line_hl_group = item.line_hl_group,
			});
		end
	end

	return decor_width;

	---|fE
end

message.cmdline_offset = function ()
	if (vim.g.__ui_cmd_height or 0) > 0 then
		return (vim.g.__ui_cmd_height or 0) + (spec.config.cmdline.row_offset or 1)
	end

	return (vim.g.__ui_cmd_height or 0);
end

message.render = function ()
	---|fS

	message.prepare();
	message.visible_decorations = {};

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

	local function handle_msg_orders (orders, msgs)
		for _, msg_order in ipairs(orders) do
			local msg = msgs[msg_order];
			local m_lines, m_exts = utils.process_content(msg.content);

			local style = spec.get_msg_style(msg, m_lines, m_exts) or {};
			if style.modifier then
				m_lines = style.modifier.lines or m_lines;
				m_exts = style.modifier.extmarks or m_exts;
			end

			if style.decorations then
				table.insert(message.visible_decorations, vim.tbl_extend("force", style.decorations, {
					from = #lines,
					to = (#lines + #m_lines) - 1,
				}));
			end

			lines = vim.list_extend(lines, m_lines);
			extmarks = vim.list_extend(extmarks, m_exts);
		end
	end

	handle_msg_orders(msg_orders, message.visible)

	table.sort(sp_msg_orders);
	handle_msg_orders(sp_msg_orders, message.visible_special)

	while lines[#lines] == "" do
		table.remove(lines);
	end

	vim.api.nvim_buf_clear_namespace(message.data.buffer, message.data.namespace, 0, -1);
	vim.api.nvim_buf_set_lines(message.data.buffer, 0, -1, false, lines);

	message.apply_extmarks("HERE", message.data.buffer, extmarks);
	local decor_size = message.apply_msg_decorations();

	local width = math.min(
		math.floor(vim.o.columns * 0.5),
		utils.max_len(lines)
	);
	local height = utils.wrapped_height(lines, width);

	local window_opts = vim.tbl_extend("force", spec.config.message.message_winconfig or {}, {
		relative = "editor",
		anchor = "SE",

		row = vim.o.lines - (1 + message.cmdline_offset()),
		col = vim.o.columns,

		width = width + decor_size,
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
			message.showmode_resize();
			message.render();
		end
	});

	vim.api.nvim_create_autocmd("TabLeave", {
		callback = function ()
			pcall(vim.api.nvim_win_close, message.data.window, true);
			pcall(vim.api.nvim_win_close, message.data.showmode_window, true);
		end
	});

	vim.api.nvim_create_autocmd({
		"VimEnter",
		"TabEnter"
	}, {
		callback = function ()
			message.render();
		end
	});

	---|fE
end

return message;

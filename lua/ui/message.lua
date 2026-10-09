--- Custom message for Neovim.
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
---@field showcmd_buffer? integer
---@field showcmd_window? integer
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

	showcmd_buffer = nil,
	showcmd_window = nil,

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
message.history_decorations = {}

---@param id string | integer Item id to remove.
---@param duration? integer Duration(in ms) until activation.
---@param interval? integer Delay between repeats(`nil` disables repeating).
message.timer = function(id, duration, interval)
	---|fS

	local timer = vim.uv.new_timer();

	if timer then
		timer:start(duration or 5000, interval or 0, vim.schedule_wrap(function()
			message.free(id);
		end));
	end

	return timer;

	---|fE
end

---@param id string | integer Item `id` to free.
message.free = function(id)
	---|fS

	if type(id) == "string" then
		message.visible_special[id] = nil;
	else
		message.visible[id] = nil;
	end

	vim.schedule(function()
		log.assert(
			"ui/message.lua → remove_render",
			pcall(message.render)
		);
	end);

	---|fE
end

---@param kind ui.message.kind
---@param content ui.message.fragment[]
---@param replace_last boolean
---@param history boolean
---@param id string | integer
---@param _type? ui.message.type
---@return ui.message.entry
message.new = function(kind, content, replace_last, history, _, id, _, _type)
	---|fS

	---@type ui.message.type
	local type = "normal";

	if _type then
		type = _type;
	elseif kind == "confirm" then
		type = "confirm";
	elseif not history then
		type = "hidden";
	end

	return {
		id = id,
		kind = kind,
		type = type,

		content = content,

		replace_last = replace_last,
		add_to_history = history,

		timer = nil,
	} --[[@as ui.message.entry]];

	---|fE
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

---@param key string Key to handle.
message.confirm_movement = function(key)
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
---@param id string | integer
---@param trigger string
message.msg_confirm = function(kind, content, replace_last, history, append, id, trigger)
	---|fS

	local msg = message.new(kind, content, replace_last, history, append, id, trigger, "confirm");
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

	vim.on_key(function(key)
		if not vim.list_contains(vim.g.__confirm_keys or {}, string.lower(key)) then
			if vim.list_contains(movement_keys, key) then
				pcall(message.confirm_movement, key);
				pcall(vim.cmd, "mode"); ---@diagnostic disable-line
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
---@param id string | integer
---@param trigger string
message.msg_list = function(kind, content, replace_last, history, append, id, trigger)
	---|fS

	local msg = message.new(kind, content, replace_last, history, append, id, trigger, "list");
	message.history[id] = msg;
	message.prepare();

	vim.api.nvim_buf_set_keymap(message.data.list_buffer, "n", "q", "", {
		callback = function()
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
		math.floor(vim.o.columns * 0.75),
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
---@param id string | integer
---@param trigger string
message.msg_show = function(kind, content, replace_last, history, append, id, trigger)
	---|fS

	vim.schedule(function()
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
	end);

	---|fE
end

local showcmd_hide_timer = vim.uv.new_timer();

message.showcmd_hide = function()
	---|fS

	if not showcmd_hide_timer then
		showcmd_hide_timer = vim.uv.new_timer();
	end

	if showcmd_hide_timer then
		showcmd_hide_timer:stop();
		showcmd_hide_timer:start(500, 0, vim.schedule_wrap(function()
			pcall(vim.api.nvim_win_close, message.data.showcmd_window, true);
			pcall(vim.api.nvim_buf_set_lines, message.data.showcmd_buffer, 0, -1, false, {})
		end));
	end

	---|fE
end

message.showcmd_resize = function()
	---|fS

	local success, valid = pcall(vim.api.nvim_buf_is_valid, message.data.showcmd_buffer)

	if not success or not valid then
		return;
	end

	local lines = vim.api.nvim_buf_get_lines(message.data.showcmd_buffer, 0, -1, false);

	if not lines[1] or lines[1] == "" then
		return;
	end

	if vim.api.nvim_win_is_valid(message.data.showcmd_window) then
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

		vim.api.nvim_win_set_config(message.data.showcmd_window, window_opts);
		utils.redraw({
			flush = true,
			win = message.data.showcmd_window
		}, {
			ignore = false,
		});
	end

	---|fE
end

---@param content ui.message.fragment[]
message.msg_showcmd = function(content)
	---|fS

	if #content == 0 then
		message.showcmd_hide();
		return;
	end

	message.prepare();

	local lines, extmarks = utils.process_content(content);
	local modifier = utils.eval(spec.config.message.showcmd.modifier, content, lines, extmarks);

	if modifier then
		lines = modifier.lines or lines;
		extmarks = modifier.extmarks or extmarks;
	end

	vim.api.nvim_buf_clear_namespace(message.data.showcmd_buffer, message.data.namespace, 0, -1);
	vim.api.nvim_buf_set_lines(message.data.showcmd_buffer, 0, -1, false, lines);
	message.apply_extmarks("msg_list", message.data.showcmd_buffer, extmarks);

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

	vim.api.nvim_win_set_config(message.data.showcmd_window, window_opts);
	pcall(vim.api.nvim_win_set_cursor, message.data.showcmd_window, { 0, width })


	vim.api.nvim__redraw({
		flush = true,
		win = message.data.showcmd_window
	})

	---|fE
end

---@param items ui.message.entry[] Items used for reloading the history window.
message.history_keymaps = function(items)
	---|fS

	if not message.data.history_buffer then
		return;
	end

	vim.api.nvim_buf_set_keymap(message.data.history_buffer, "n", "u", "", {
		desc = "[u]pdates message history.",
		callback = function()
			if vim.g.history_source == "vim" then
				vim.cmd("message");
			else
				message.msg_history_show(items);
			end
		end
	});
	vim.api.nvim_buf_set_keymap(message.data.history_buffer, "n", "t", "", {
		desc = "[t]oggles between `vim` and `ui.nvim`'s message history.",
		callback = function()
			if vim.g.history_source == "vim" then
				vim.g.history_source = "ui";
			else
				vim.g.history_source = "vim";
			end

			message.msg_history_show(items);
		end
	});

	vim.api.nvim_buf_set_keymap(message.data.history_buffer, "n", "q", "", {
		desc = "[q]uit",
		callback = function()
			log.assert(
				"ui/message.lua → history_quit",
				pcall(vim.api.nvim_win_close, message.data.history_window, true)
			)
		end
	});

	vim.api.nvim_buf_set_keymap(message.data.history_buffer, "n", "N", "", {
		desc = "Toggles [N]ormal msssags visiblity.",
		callback = function()
			if _G.history_show then
				_G.history_show.normal = not _G.history_show.normal;
			end

			message.msg_history_show(items);
		end
	});
	vim.api.nvim_buf_set_keymap(message.data.history_buffer, "n", "H", "", {
		desc = "Toggles [H]idden msssags visiblity.",
		callback = function()
			if _G.history_show then
				_G.history_show.hidden = not _G.history_show.hidden;
			end

			message.msg_history_show(items);
		end
	});
	vim.api.nvim_buf_set_keymap(message.data.history_buffer, "n", "L", "", {
		desc = "Toggles [L]ist msssags visiblity.",
		callback = function()
			if _G.history_show then
				_G.history_show.list = not _G.history_show.list;
			end

			message.msg_history_show(items);
		end
	});
	vim.api.nvim_buf_set_keymap(message.data.history_buffer, "n", "C", "", {
		desc = "Toggles [C]onfirm msssags visiblity.",
		callback = function()
			if _G.history_show then
				_G.history_show.confirm = not _G.history_show.confirm;
			end

			message.msg_history_show(items);
		end
	});

	---|fE
end

---@param items ui.message.entry[]
message.msg_history_show = function(items)
	---|fS

	vim.g.history_source = vim.g.history_source or "vim";
	_G.history_show = _G.history_show or {
		normal = true,

		hidden = false,
		list = false,
		confirm = false,
	};

	message.prepare();
	message.history_keymaps(items);

	message.history_decorations = {};

	local lines, extmarks = {}, {};

	if vim.g.history_source == "vim" then
		for _, item in ipairs(items) do
			local i_lines, i_extmarks = utils.process_content(item[2]);

			lines = vim.list_extend(lines, i_lines);
			extmarks = vim.list_extend(extmarks, i_extmarks);
		end
	else
		local ui_chips = {
			{ " [N]ormal ",  _G.history_show.normal },
			{ " [H]idden ",  _G.history_show.hidden },
			{ " [L]ist ",    _G.history_show.list },
			{ " [C]onfirm ", _G.history_show.confirm },
		};

		-- Taken from `ZeroBrane`
		local function padnum(d)
			return ("%03d%s"):format(#d, d)
		end

		local line, extmark = " Filters ", {
			{ 0, 11, "Comment" }
		};

		for i, item in ipairs(ui_chips) do
			local before = #line;
			line = line .. item[1] .. (i ~= #ui_chips and " " or "");

			table.insert(extmark,
				{ before, before + #item[1], item[2] and "UICmdlineDefaultIcon" or "UICmdlineSearchUpIcon" })
		end

		table.insert(lines, line);
		table.insert(extmarks, extmark);

		local msg_orders = vim.tbl_keys(message.history);
		table.sort(msg_orders, function (a, b)
			if type(a) == "number" and type(b) == "number" then
				return a < b;
			else
				-- There may be special message order(e.g. `bufwrite`), this is an Overkill BTW.
				return tostring(a):gsub("%d+", padnum) < tostring(b):gsub("%d+", padnum);
			end
		end);

		for _, order in ipairs(msg_orders) do
			local msg = message.history[order];

			if _G.history_show[msg.type or "normal"] then
				local m_lines, m_exts = utils.process_content(msg.content);

				local style = spec.get_msg_style(msg, m_lines, m_exts) or {};
				if style.modifier then
					m_lines = style.modifier.lines or m_lines;
					m_exts = style.modifier.extmarks or m_exts;
				end

				if style.decorations then
					table.insert(message.history_decorations, vim.tbl_extend("force", style.decorations, {
						from = #lines,
						to = (#lines + #m_lines) - 1,
					}));
				end

				lines = vim.list_extend(lines, m_lines);
				extmarks = vim.list_extend(extmarks, m_exts);
			end
		end
	end

	vim.bo[message.data.history_buffer].modifiable = true;

	vim.api.nvim_buf_clear_namespace(message.data.history_buffer, message.data.namespace, 0, -1);
	vim.api.nvim_buf_set_lines(message.data.history_buffer, 0, -1, false, lines);

	vim.bo[message.data.history_buffer].modifiable = false;

	if vim.g.history_source == "vim" then
		vim.wo[message.data.history_window].statusline = table.concat({
			"%#UILSBufname#",
			" VIM ",
			"%#Normal#",
			"%=",
			"%#UIHistoryKeymap#",
			" t ",
			"%#UIHistoryDesc#",
			" Toggle source ",
			"%#Normal#",
			"  ",
			"%#UIHistoryKeymap#",
			" q ",
			"%#UIHistoryDesc#",
			" Quit ",
		}, "");
	else
		vim.wo[message.data.history_window].statusline = table.concat({
			"%#UILSBuffer#",
			" UI.nvim ",
			"%#Normal#",
			"%=",
			"%#UIHistoryKeymap#",
			" u ",
			"%#UIHistoryDesc#",
			" Update ",
			"%#Normal#",
			"  ",
			"%#UIHistoryKeymap#",
			" t ",
			"%#UIHistoryDesc#",
			" Toggle source ",
			"%#Normal#",
			"  ",
			"%#UIHistoryKeymap#",
			" q ",
			"%#UIHistoryDesc#",
			" Quit ",
		}, "");
	end

	message.apply_extmarks("HERE", message.data.history_buffer, extmarks);
	message.apply_msg_decorations(message.history_decorations, message.data.history_buffer);

	local window_opts = vim.tbl_extend("force", spec.config.message.history_winconfig or {}, {
		split = "below",
		win = -1,

		height = 10,
	});

	vim.api.nvim_win_set_config(message.data.history_window, window_opts);
	vim.api.nvim_set_current_win(message.data.history_window);

	---|fE
end

------------------------------------------------------------------------------

---@return string
message.statuscolumn = function()
	---|fS

	local win = vim.g.statusline_winid;

	if win ~= message.data.window and win ~= message.data.history_window then
		return "";
	end

	local row = vim.v.lnum - 1;

	for _, item in ipairs(win == message.data.window and message.visible_decorations or message.history_decorations) do
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
				return utils.to_statuscolumn(item.padding or item.icon);
			end

			break;
		end
	end

	return "";

	---|fE
end

_G.ui_statuscolumn = message.statuscolumn;

--- Creates a buffer & window pair & assign them to `message.data`
---@param buf string Buffer name
---@param win string Window name
message.set_buf_win = function(buf, win)
	---|fS

	---@type vim.api.keyset.win_config
	local window_opts = {
		relative = "editor",

		row = 0,
		col = 0,
		width = 1,
		height = 1,

		border = "none",
		style = "minimal",

		hide = true,
		focusable = false
	};

	if not message.data[buf] or not vim.api.nvim_buf_is_valid(message.data[buf]) then
		message.data[buf] = vim.api.nvim_create_buf(false, true);
	end

	if not message.data[win] or not vim.api.nvim_win_is_valid(message.data[win]) then
		message.data[win] = vim.api.nvim_open_win(message.data[buf], false, window_opts);
		vim.api.nvim_win_set_var(message.data[win], "ui_window", true);

		utils.set("w", message.data[win], "foldmethod", "manual");
		utils.set("w", message.data[win], "numberwidth", 1);
		utils.set("w", message.data[win], "winhl", "Normal:Normal");
	end

	---|fE
end

--- Prepare all buffers & windows used for messages.
message.prepare = function()
	---|fS

	message.set_buf_win("buffer", "window");
	message.set_buf_win("confirm_buffer", "confirm_window");
	message.set_buf_win("list_buffer", "list_window");
	message.set_buf_win("history_buffer", "history_window");
	message.set_buf_win("showcmd_buffer", "showcmd_window");

	utils.set("w", message.data.window, "statuscolumn", "%!v:lua.ui_statuscolumn()");
	utils.set("w", message.data.window, "wrap", true);

	utils.set("w", message.data.history_window, "statuscolumn", "%!v:lua.ui_statuscolumn()");
	utils.set("w", message.data.showcmd_window, "sidescrolloff", 999)

	---|fE
end

---@param src string Source used for logs
---@param buffer integer Buffer ID
---@param extmarks ui.message.hl_fragment[][]
message.apply_extmarks = function(src, buffer, extmarks)
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

---@param src ui.message.decorations[]
---@return integer
message.apply_msg_decorations = function(src, buffer)
	---|fS

	local decor_width = 0;

	for _, item in ipairs(src) do
		if item.icon then
			decor_width = math.max(decor_width, utils.virt_len(item.icon));
		end

		if item.line_hl_group then
			pcall(vim.api.nvim_buf_set_extmark, buffer, message.data.namespace, item.from, 0, {
				end_row = item.to,
				line_hl_group = item.line_hl_group,
			});
		end
	end

	return decor_width;

	---|fE
end

---@return integer RowOffset Rows used by the command-line
message.cmdline_offset = function()
	return (vim.g.ui_cmd_height or 0) + (spec.config.cmdline.row_offset or 0) - 1
end

message.render = function()
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

	local function handle_msg_orders(orders, msgs)
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

	message.apply_extmarks("msg_render", message.data.buffer, extmarks);
	local decor_size = message.apply_msg_decorations(message.visible_decorations, message.data.buffer);

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
message.handle = function(event, ...)
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

message.setup = function()
	---|fS

	vim.api.nvim_create_autocmd("VimResized", {
		callback = function()
			message.showcmd_resize();
			message.render();
		end
	});

	vim.api.nvim_create_autocmd("TabLeave", {
		callback = function()
			pcall(vim.api.nvim_win_close, message.data.window, true);
			pcall(vim.api.nvim_win_close, message.data.showcmd_window, true);
		end
	});

	vim.api.nvim_create_autocmd({
		"VimEnter",
		"TabEnter"
	}, {
		callback = function()
			message.render();
		end
	});

	---|fE
end

return message;

--- Custom message for
--- Neovim.
local message = {};

local log = require("ui.log");
local spec = require("ui.spec");
local utils = require("ui.utils");

------------------------------------------------------------------------------

---@type integer Namespace for decorations in messages.
message.namespace = vim.api.nvim_create_namespace("ui.message")

---@type integer, integer Buffer & window for messages.
message.msg_buffer, message.msg_window = nil, nil;

---@type integer, integer Buffer & window for showing larger messages.
message.list_buffer, message.list_window = nil, nil;

---@type integer, integer Buffer & window for confirmation messages.
message.confirm_buffer, message.confirm_window = nil, nil;

---@type integer, integer Buffer & window for message history.
message.history_buffer, message.history_window = nil, nil;

---@type integer, integer Buffer & window for showmode.
message.show_buffer, message.show_window = nil, nil;

------------------------------------------------------------------------------

---@type integer Current message ID.
message.id = 2000;

---@type ui.message.entry[] Message history(stores messages not available in `:messages`).
message.history = {};
---@type ui.message.entry[] Currently visible message.
message.visible = {};

---@type ui.message.decorations[] Decorations to show in the statuscolumn.
message.decorations = {};

---@type ui.message.decorations[] Decorations to show in the statuscolumn for history.
message.history_decorations = {};

--- Custom statuscolumn for the message window.
---@return string
message.statuscolumn = function ()
	---|fS

	local win = vim.g.statusline_winid;

	if win ~= message.msg_window and win ~= message.history_window then
		-- Wrong window.
		return "";
	elseif not message.decorations and not message.history_decorations then
		-- Decorations not available.
		return "";
	end

	---@type integer Current line-number(0-indexed).
	local lnum = vim.v.lnum - 1;

	for _, entry in ipairs(win == message.history_window and (message.history_decorations or {}) or (message.decorations or {})) do
		if lnum >= entry.from and lnum <= entry.to then
			if lnum == entry.from and vim.v.virtnum == 0 then
				return utils.to_statuscolumn(entry.icon);
			elseif lnum == entry.to and vim.v.virtnum == 0 then
				return utils.to_statuscolumn(
					entry.tail or entry.padding or entry.icon
				);
			else
				return utils.to_statuscolumn(
					entry.padding or entry.icon
				);
			end

			break;
		end
	end

	return "";

	---|fE
end

-- Export the statuscolumn so that we can use it in 'statuscolumn' option.
_G.__ui_statuscolumn = message.statuscolumn;

------------------------------------------------------------------------------

---@type boolean Have we passed UIEnter event?
message.ui_attached = false;
---@type ui.message.entry[] List of messages to echo after UIEnter.
message.ui_echo = {};

--- Caches given message.
---@param kind ui.message.kind
---@param content ui.message.fragment[]
---@param replace_last boolean
---@param add_to_history boolean
message.cache = function (kind, content, replace_last, add_to_history)
	---|fS

	if #message.ui_echo > 0 and replace_last == true then
		message.ui_echo[#message.ui_echo] = {
			kind = kind,
			content = content,
			replace_last = replace_last,

			add_to_history = add_to_history
		};
	else
		table.insert(message.ui_echo, {
			kind = kind,
			content = content,
			replace_last = replace_last,

			add_to_history = add_to_history
		});
	end

	---|fE
end

vim.api.nvim_create_autocmd("UIEnter", {
	callback = function ()
		message.ui_attached = true;

		for _, item in ipairs(message.ui_echo) do
			message.__add(item.kind, item.content, item.add_to_history or true);
		end
	end
});

------------------------------------------------------------------------------

--- Prepares various window & buffers.
message.__prepare = function ()
	---|fS

	local win_config = {
		relative = "editor",

		row = 0, col = 0,
		width = 1, height = 1,

		border = "none",

		style = "minimal",
		hide = true,
		focusable = false
	};

	if not message.msg_buffer or vim.api.nvim_buf_is_valid(message.msg_buffer) == false then
		message.msg_buffer = vim.api.nvim_create_buf(false, true);
	end

	if not message.msg_window or vim.api.nvim_win_is_valid(message.msg_window) == false then
		message.msg_window = vim.api.nvim_open_win(message.msg_buffer, false, win_config);
		vim.api.nvim_win_set_var(message.msg_window, "ui_window", true);

		utils.set("w", message.msg_window, "numberwidth", 1);
		utils.set("w", message.msg_window, "statuscolumn", "%!v:lua.__ui_statuscolumn()");
	end

	----------

	if not message.list_buffer or vim.api.nvim_buf_is_valid(message.list_buffer) == false then
		message.list_buffer = vim.api.nvim_create_buf(false, true);
	end

	----------

	if not message.confirm_buffer or vim.api.nvim_buf_is_valid(message.confirm_buffer) == false then
		message.confirm_buffer = vim.api.nvim_create_buf(false, true);
	end

	----------

	if not message.history_buffer or vim.api.nvim_buf_is_valid(message.history_buffer) == false then
		message.history_buffer = vim.api.nvim_create_buf(false, true);
	end

	----------

	if not message.show_buffer or vim.api.nvim_buf_is_valid(message.show_buffer) == false then
		message.show_buffer = vim.api.nvim_create_buf(false, true);
	end

	if not message.show_window or vim.api.nvim_win_is_valid(message.show_window) == false then
		message.show_window = vim.api.nvim_open_win(message.show_buffer, false, win_config);
		vim.api.nvim_win_set_var(message.show_window, "ui_window", true);

		utils.set("w", message.show_window, "sidescrolloff", 0);
	end

	---|fE
end

--- Wrapper for `vim.uv.new_timer()`.
---@param callback function
---@param duration? integer
---@param interval? integer
---@return table
message.timer = function (callback, duration, interval)
	---|fS

	local timer = vim.uv.new_timer(); ---@diagnostic disable-line

	if interval then
		timer:start(0, duration, vim.schedule_wrap(callback));
	else
		timer:start(duration, 0, vim.schedule_wrap(callback));
	end

	return timer;

	---|fE
end

--- Removes message with `ID`.
---@param id integer
message.__remove = function (id)
	---|fS

	if message.visible[id] then
		message.visible[id] = nil;

		vim.schedule(function ()
			log.assert(
				"ui/message.lua → remove_render",
				pcall(message.__render)
			)
		end)
	end

	---|fE
end

--- Adds a new message.
---@param kind ui.message.kind
---@param content ui.message.fragment[]
---@param add_to_history boolean
message.__add = function (kind, content, add_to_history)
	---|fS

	if kind == "" and vim.tbl_isempty(message.visible) == false then
		---@type integer[] Message IDs.
		local IDs = vim.tbl_keys(message.visible);
		table.sort(IDs);

		--- Last visible message.
		local last = message.visible[IDs[#IDs]];

		if vim.deep_equal(last.content, content) then
			-- BUG, Vim resends old message on redraw.
			-- Last message will be replaced with this
			-- one.
			--
			-- The second message has the wrong kind so
			-- we use the original kind.

			message.__replace(last.kind, content, false);
			return;
		end
	end

	vim.schedule(function ()
		---|fS

		---@type boolean Should this message be ignored?
		local condition = utils.eval(spec.config.message.ignore, kind, content);

		if condition == true then
			return;
		end

		local lines = utils.to_lines(content);

		---@type boolean, boolean?
		local is_list, _add_to_history = spec.is_list(kind, content, add_to_history);
		local max_lines = spec.config.message.max_lines or math.floor(vim.o.lines * 0.5);

		if is_list == true or #lines > max_lines then
			-- The message should be shown as a list.
			-- It either,
			--     1. Is a list message with inaccurate `kind`.
			--     2. Is too long to show.
			log.assert(
				"ui/message.lua → add_list",
				pcall(message.__list, {
					kind = kind,
					content = content,

					-- If the message is too long, it should be
					-- added to history.
					add_to_history = _add_to_history or #lines > max_lines
				})
			);
			return;
		elseif kind == "list_cmd" then
			-- If the message isn't considered a list command,
			-- we should change it's kind even if Neovim tells
			-- us otherwise.
			kind = "not_list_cmd";
		end

		---@type integer Current message's ID.
		local current_id = message.id;

		---@type ui.message.style__static
		local style = spec.get_msg_style({ kind = kind, content = content }, lines, {}) or {};

		---@type integer Message visibility duration.
		local duration = math.min(
			style.duration or 5000,
			spec.config.message.max_duration or 5000
		);

		-- Store the message in history & visible
		-- message table.
		if add_to_history then
			message.history[message.id] = {
				kind = kind,
				content = content
			};
		end

		-- The visible message has a `timer`
		-- thta shows/hides the message.
		message.visible[message.id] = vim.tbl_extend("force", {
			kind = kind,
			content = content
		}, {
			timer = message.timer(function ()
				message.__remove(current_id);
			end, duration)
		});

		message.id = message.id + 1;

		log.assert(
			"ui/message.lua → add_render",
			pcall(message.__render)
		);

		---|fE
	end);

	---|fE
end

--- Replaces the last visible message.
---@param kind ui.message.kind
---@param content ui.message.fragment[]
---@param add_to_history boolean
message.__replace = function (kind, content, add_to_history)
	---|fS

	vim.schedule(function ()
		---@type boolean Should this message be ignored?
		local condition = utils.eval(spec.config.message.ignore, kind, content, true);

		if condition == true then
			return;
		end

		---@type integer[]
		local keys = vim.tbl_keys(message.visible);

		local lines = utils.to_lines(content);

		---@type boolean, boolean?
		local is_list, _add_to_history = spec.is_list(kind, content, add_to_history);
		local max_lines = spec.config.message.max_lines or math.floor(vim.o.lines * 0.5);

		if is_list == true or #lines > max_lines then
			log.assert(
				"ui/message.lua → replace_list",
				pcall(message.__list, {
					kind = kind,
					content = content,

					-- If the message is too long, it should be
					-- added to history.
					add_to_history = _add_to_history or #lines > max_lines
				})
			);
			return;
		elseif #keys == 0 or not message.visible[keys[#keys]] then
			-- No last visible message available.
			-- Add new message.
			message.__add(kind, content, add_to_history);
			return;
		elseif add_to_history then
			-- Certain replace type messages need
			-- to be added to the history.
			message.history[message.id] = {
				kind = kind,
				content = { {1, "hi", 178 }} or content
			};
			message.id = message.id + 1;
		else
			message.history[keys[#keys]] = {
				kind = kind,
				content = content
			};
		end

		--- Last visible message.
		local last = message.visible[keys[#keys]];

		last.timer:stop();

		last.kind = kind;
		last.content = content;

		---@type ui.message.style__static
		local style = spec.get_msg_style({ kind = kind, content = content }, lines, {}) or {};
		local duration = math.min(
			style.duration or 5000,
			spec.config.message.max_duration or 5000
		);

		last.timer:start(duration, 0, vim.schedule_wrap(function ()
			message.__remove(keys[#keys]);
		end));

		log.assert(
			"ui/message.lua → replace_render",
			pcall(message.__render)
		);
	end);

	---|fE
end

------------------------------------------------------------------------------

--- Confirmation message.
---@param obj ui.message.entry
message.__confirm = function (obj)
	---|fS

	--- All logic must be run outside of
	--- fast event.
	vim.schedule(function ()
		vim.g.__ui_confirm_msg = obj;
		local lines, exts = utils.process_content(obj.content);

		message.__prepare();

		---@type ui.message.confirm__static
		local config = spec.get_confirm_style(obj, lines, exts);

		if config.modifier then
			lines = config.modifier.lines or lines;
			exts = config.modifier.extmarks or exts;
		end

		local window_config = vim.tbl_extend("force", {
			relative = "editor",

			row = config.row or math.ceil((vim.o.lines - #lines) / 2),
			col = config.col or math.ceil((vim.o.columns - utils.max_len(lines)) / 2),

			width = config.width or utils.max_len(lines),
			height = config.height or utils.wrapped_height(lines, config.width),

			border = config.border or "none",
			style = "minimal",

			zindex = 90,
			hide = false
		}, spec.config.message.confirm_winconfig or {});

		if message.confirm_window and vim.api.nvim_win_is_valid(message.confirm_window) then
			vim.api.nvim_win_set_config(message.confirm_window, window_config);
		else
			message.confirm_window = vim.api.nvim_open_win(message.confirm_buffer, false, window_config);
			vim.api.nvim_win_set_var(message.confirm_window, "ui_window", true);
		end

		vim.api.nvim_win_set_cursor(message.confirm_window, { 1, 0 });
		vim.api.nvim_buf_clear_namespace(message.confirm_buffer, message.namespace, 0, -1);
		vim.api.nvim_buf_set_lines(message.confirm_buffer, 0, -1, false, lines);

		for l, line in ipairs(exts) do
			for _, ext in ipairs(line) do
				vim.api.nvim_buf_set_extmark(message.confirm_buffer, message.namespace, l - 1, ext[1], {
					end_col = ext[2],
					hl_group = ext[3]
				});
			end
		end

		utils.set("w", message.confirm_window, "wrap", true);
		utils.set("w", message.confirm_window, "linebreak", true);
		utils.set("w", message.confirm_window, "cursorline", #lines > 1);

		if config.winhl then
			utils.set("w", message.confirm_window, "winhl", config.winhl);
		end

		---|fS "feat: Allow moving in the confirm window."

		---@type string[] Various movement keys
		local movememt_keys = {
			vim.api.nvim_replace_termcodes("<left>", true, true, true),
			vim.api.nvim_replace_termcodes("<right>", true, true, true),

			vim.api.nvim_replace_termcodes("<down>", true, true, true),
			vim.api.nvim_replace_termcodes("<up>", true, true, true),

			vim.api.nvim_replace_termcodes("h", true, true, true),
			vim.api.nvim_replace_termcodes("l", true, true, true),

			vim.api.nvim_replace_termcodes("j", true, true, true),
			vim.api.nvim_replace_termcodes("k", true, true, true),
		};

		---  Handles cursor movements.
		---@param key string
		local function handle_movement (key)
			---|fS

			local pos = vim.api.nvim_win_get_cursor(message.confirm_window);
			local X, Y = pos[2], pos[1];

			if key == movememt_keys[1] or key == movememt_keys[5] then
				X = math.max(0, X - 1);
			elseif key == movememt_keys[2] or key == movememt_keys[6] then
				X = math.min(string.len(lines[Y] or ""), X + 1);
			elseif key == movememt_keys[3] or key == movememt_keys[7] then
				Y = math.min(#lines, Y + 1);
			else
				Y = math.max(1, Y - 1);
			end

			pcall(vim.api.nvim_win_set_cursor, message.confirm_window, { Y, X });

			---|fE
		end

		---|fE

		--- Auto hide on next key press.
		vim.on_key(function (key)
			if vim.list_contains(vim.g.__confirm_keys or {}, string.lower(key)) == false then
				if vim.list_contains(movememt_keys, key) then
					-- If the key is a movement key then
					-- we try to do the movement and
					-- redraw the entire screen.
					-- `nvim__redraw()` doesn't work
					-- here.
					pcall(handle_movement, key);
					pcall(vim.cmd, "mode"); ---@diagnostic disable-line
				end

				return;
			end

			pcall(vim.api.nvim_win_close, message.confirm_window, true);
			vim.on_key(nil, message.namespace);

			vim.g.__ui_confirm_msg = nil;
		end, message.namespace);
	end);

	---|fE
end

--- List message.
---@param obj ui.message.entry
message.__list = function (obj)
	---|fS

	if obj.add_to_history then
		message.history[message.id] = obj;
		message.id = message.id + 1;
	end

	--- All logic must be run outside of
	--- fast event.
	vim.schedule(function ()
		message.__prepare();
		vim.g.__ui_list_msg = obj;

		local lines, exts = utils.process_content(obj.content);

		---@type ui.message.list__static
		local config = spec.get_listmsg_style(obj, lines, exts);

		if config.modifier then
			lines = config.modifier.lines or lines;
			exts = config.modifier.extmarks or exts;
		end

		---|fS "feat: Keymap(s)"

		vim.api.nvim_buf_set_keymap(message.list_buffer, "n", "q", "", {
			callback = function ()
				vim.api.nvim_set_current_win(
					utils.last_win()
				);
				pcall(vim.api.nvim_win_close, message.list_window, true);

				vim.g.__ui_list_msg = nil;
			end
		});

		---|fE

		---@type integer
		local W = math.min(utils.max_len(lines), math.floor(vim.o.columns * 0.75));
		---@type integer
		local H = math.min(utils.wrapped_height(lines, W), vim.o.lines - 2);

		local window_config = vim.tbl_extend("force", {
			relative = "editor",

			row = config.row or math.ceil((vim.o.lines - H) / 2),
			col = config.col or math.ceil((vim.o.columns - W) / 2),

			width = config.width or W,
			height = config.height or H,

			border = config.border or "none",
			style = "minimal",

			zindex = 50,
			hide = false,
			focusable = true
		}, spec.config.message.list_winconfig or {});

		if message.list_window and vim.api.nvim_win_is_valid(message.list_window) then
			vim.api.nvim_win_set_config(message.list_window, window_config);
		else
			message.list_window = vim.api.nvim_open_win(message.list_buffer, false, window_config);
			vim.api.nvim_win_set_var(message.list_window, "ui_window", true);

			vim.api.nvim_create_autocmd("WinClosed", {
				pattern = tostring(message.list_window),
				callback = function ()
					message.list_window = nil;
					vim.g.__ui_list_msg = nil;
				end
			})
		end

		---|fS

		vim.bo[message.list_buffer].modifiable = true;

		vim.api.nvim_buf_clear_namespace(message.list_buffer, message.namespace, 0, -1);
		vim.api.nvim_buf_set_lines(message.list_buffer, 0, -1, false, lines);

		for l, line in ipairs(exts) do
			for _, ext in ipairs(line) do
				log.assert(
					"ui/message.lua → list_highlights",
					pcall(
						vim.api.nvim_buf_set_extmark,
						message.list_buffer,
						message.namespace,

						l - 1,
						ext[1],

						{
							end_col = ext[2],
							hl_group = ext[3]
						}
					)
				);
			end
		end

		vim.bo[message.list_buffer].modifiable = false;

		---|fE

		vim.api.nvim_set_current_win(message.list_window);

		if config.winhl then
			utils.set("w", message.list_window, "winhl", config.winhl);
		end
	end);

	---|fE
end

message.__list_resize = function ()
	---|fS

	if not vim.g.__ui_list_msg then
		return;
	elseif not message.list_window or not vim.api.nvim_win_is_valid(message.list_window) then
		return;
	end

	local lines, exts = utils.process_content(vim.g.__ui_list_msg.content);

	---@type ui.message.list__static
	local config = spec.get_listmsg_style(vim.g.__ui_list_msg, lines, exts);

	if config.modifier then
		lines = config.modifier.lines or lines;
		exts = config.modifier.extmarks or exts;
	end

	---@type integer
	local W = math.min(utils.max_len(lines), math.floor(vim.o.columns * 0.75));
	---@type integer
	local H = math.min(utils.wrapped_height(lines, W), vim.o.lines - 2);

	local window_config = vim.tbl_extend("force", {
		relative = "editor",

		row = config.row or math.ceil((vim.o.lines - H) / 2),
		col = config.col or math.ceil((vim.o.columns - W) / 2),

		width = config.width or W,
		height = config.height or H,

		border = config.border or "none",
		style = "minimal",

		zindex = 90,
		hide = false,
		focusable = true
	}, spec.config.message.list_winconfig or {});

	vim.api.nvim_win_set_config(message.list_window, window_config);

	---|fE
end

--- Hides the message window.
message.__hide = function ()
	---|fS

	local keys = vim.tbl_keys(message.visible);
	if #keys ~= 0 then return; end

	pcall(vim.api.nvim_win_set_config, message.msg_window, { hide = true });

	---|fE
end

message.__get_cmdline_offset = function ()
	---|fS

	local cmdline_offset = 0

	if vim.g.__ui_cmd_height and vim.g.__ui_cmd_height > 0 then
		cmdline_offset = vim.g.__ui_cmd_height + spec.config.cmdline.row_offset - 1
	end

	return cmdline_offset

	---|fE
end

--- Renders visible messages.
message.__render = function ()
	---|fS

	local keys = vim.tbl_keys(message.visible);
	table.sort(keys);

	if #keys == 0 then
		message.__hide();
		return;
	end

	message.__prepare();

	---@type integer
	local last_decor_size = 0;

	for _, entry in ipairs(message.decorations) do
		if entry.icon then
			last_decor_size = math.max(last_decor_size, utils.virt_len(entry.icon));
		end
	end

	local lines, exts = {}, {};
	message.decorations = {};

	for _, key in ipairs(keys) do
		local value = message.visible[key];
		local m_lines, m_exts = utils.process_content(value.content);

		---@type ui.message.style__static
		local style = spec.get_msg_style(value, m_lines, m_exts) or {};

		if style.modifier then
			m_lines = style.modifier.lines or m_lines;
			m_exts = style.modifier.extmarks or m_exts;
		end

		if style.decorations then
			table.insert(message.decorations, vim.tbl_extend("force", style.decorations, {
				from = #lines,
				to = #lines + (#m_lines - 1)
			}));
		end

		lines = vim.list_extend(lines, m_lines)
		exts = vim.list_extend(exts, m_exts)
	end

	vim.api.nvim_buf_clear_namespace(message.msg_buffer, message.namespace, 0, -1);
	vim.api.nvim_buf_set_lines(message.msg_buffer, 0, -1, false, lines);

	for l, line in ipairs(exts) do
		for _, ext in ipairs(line) do
			if ext[3] == "" then
				goto continue;
			end

			vim.api.nvim_buf_set_extmark(message.msg_buffer, message.namespace, l - 1, ext[1], {
				end_col = ext[2],
				hl_group = ext[3]
			});

		    ::continue::
		end
	end

	---@type integer Number of columns decorations take.
	local decor_size = 0;

	for _, entry in ipairs(message.decorations) do
		if entry.icon then
			decor_size = math.max(decor_size, utils.virt_len(entry.icon));
		end

		if entry.line_hl_group then
			vim.api.nvim_buf_set_extmark(message.msg_buffer, message.namespace, entry.from, 0, {
				end_row = entry.to,
				line_hl_group = entry.line_hl_group
			});
		end
	end

	local W = math.min(math.floor(vim.o.columns * 0.5), utils.max_len(lines));

	local window_config = vim.tbl_extend("keep", spec.config.message.message_winconfig or {}, {
		relative = "editor",

		row = vim.o.lines - (vim.o.cmdheight + message.__get_cmdline_offset() + 1) - utils.wrapped_height(lines, W),
		col = vim.o.columns,

		width = W + decor_size,
		height = utils.wrapped_height(lines, W),

		border = "none",

		zindex = 80,
		hide = false
	});

	if message.msg_window and vim.api.nvim_win_is_valid(message.msg_window) then
		vim.api.nvim_win_set_config(message.msg_window, window_config);
	else
		message.msg_window = vim.api.nvim_open_win(message.msg_buffer, false, window_config);
		vim.api.nvim_win_set_var(message.msg_window, "ui_window", true);
	end

	utils.set("w", message.msg_window, "winhl", "Normal:Normal");
	utils.set("w", message.msg_window, "statuscolumn", "%!v:lua.__ui_statuscolumn()");

	utils.set("w", message.msg_window, "wrap", true);
	utils.set("w", message.msg_window, "linebreak", true);

	vim.api.nvim__redraw({
		flush = true,
		-- BUG, Visual artifacts are shown if the statuscolumn
		-- is updated repeatedly.
		-- Solution: Update when the decoration size changes.
		statuscolumn = last_decor_size ~= decor_size,

		win = message.msg_window
	});

	---|fE
end

--- Loads history in a window.
---@param entries ( ui.message.fragment[] )[]
message.__history = function (entries)
	---|fS

	---@type "vim" | "ui" Message history source preference.
	vim.g.__ui_history_pref = vim.g.__ui_history_pref or spec.config.message.history_preference;
	vim.g.__ui_history = true;

	message.__prepare();
	message.history_decorations = {};

	---|fS "feat: Keymaps"

	vim.api.nvim_buf_set_keymap(message.history_buffer, "n", "u", "<CMD>messages<CR>", {
		desc = "[u]pdates message history.",
	});
	vim.api.nvim_buf_set_keymap(message.history_buffer, "n", "t", "", {
		desc = "[t]oggles between `vim` and `ui.nvim`'s message history.",
		callback = function ()
			vim.g.__ui_history_pref = vim.g.__ui_history_pref == "vim" and "ui" or "vim";
			message.__history(entries);
		end
	});

	vim.api.nvim_buf_set_keymap(message.history_buffer, "n", "q", "", {
		desc = "[q]uits message window.",
		callback = function ()
			---|fS

			-- Instead of closing the window, we hide it.
			--
			-- Only floating windows can be hidden so we
			-- turn it into a floating window.
			vim.api.nvim_set_current_win(
				utils.last_win()
			);
			log.assert(
				"ui/message.lua → history_quit",
				pcall(vim.api.nvim_win_close, message.history_window, true)
			);

			---|fE
		end
	});

	---|fE

	---@type string[], ( ui.message.hl_fragment[] )[]
	local lines, exts = {
		vim.g.__ui_history_pref == "vim" and " History:" or "󰋚 History:"
	}, {
		{}
	};

	---|fS

	if vim.g.__ui_history_pref == "vim" and entries then
		-- Show raw history from Vim.
		for _, entry in ipairs(entries) do
			local _lines, _exts = utils.process_content(entry[2]);

			lines = vim.list_extend(lines, _lines);
			exts = vim.list_extend(exts, _exts);
		end
	else
		-- Show history from `ui.nvim`.

		---@type integer[] List of message IDs.
		local keys = vim.tbl_keys(message.history);
		table.sort(keys);

		for _, key in ipairs(keys) do
			local value = message.history[key];
			local m_lines, m_exts = utils.process_content(value.content);

			local processor = spec.get_msg_style(value, m_lines, m_exts) or {};

			if processor.modifier then
				m_lines = processor.modifier.lines or m_lines;
				m_exts = processor.modifier.extmarks or m_exts;
			end

			if processor.history_decorations then
				table.insert(message.history_decorations, vim.tbl_extend("force", processor.history_decorations, {
					from = #lines,
					to = #lines + (#m_lines - 1)
				}));
			elseif processor.decorations then
				table.insert(message.history_decorations, vim.tbl_extend("force", processor.decorations, {
					from = #lines,
					to = #lines + (#m_lines - 1)
				}));
			end

			lines = vim.list_extend(lines, m_lines)
			exts = vim.list_extend(exts, m_exts)
		end
	end

	---|fE

	vim.bo[message.history_buffer].modifiable = true;

	vim.api.nvim_buf_clear_namespace(message.history_buffer, message.namespace, 0, -1);
	vim.api.nvim_buf_set_lines(message.history_buffer, 0, -1, false, lines);

	---|fS

	-- Add keymap hints
	vim.api.nvim_buf_set_extmark(message.history_buffer, message.namespace, 0, 0, {
		virt_text_pos = "right_align",
		virt_text = {
			{ " u ", "UIHistoryKeymap" },
			{ " Update ", "UIHistoryDesc" },
			{ " " },
			{ " t ", "UIHistoryKeymap" },
			{ " Toggle source ", "UIHistoryDesc" },
			{ " " },
			{ " q ", "UIHistoryKeymap" },
			{ " Quit ", "UIHistoryDesc" },
		},

		line_hl_group = "Comment"
	});

	---|fE

	-- Highlight lines of the buffer.
	for l, line in ipairs(exts) do
		for _, ext in ipairs(line) do
			vim.api.nvim_buf_set_extmark(message.history_buffer, message.namespace, l - 1, ext[1], {
				end_col = ext[2],
				hl_group = ext[3]
			});
		end
	end

	-- Highlight lines with decorations.
	for _, entry in ipairs(message.history_decorations) do
		if entry.line_hl_group then
			vim.api.nvim_buf_set_extmark(message.history_buffer, message.namespace, entry.from, 0, {
				end_row = entry.to,
				line_hl_group = entry.line_hl_group
			});
		end
	end

	vim.bo[message.history_buffer].modifiable = false;

	local window_config = vim.tbl_extend("force", {
		split = "below",
		win = -1, -- creates top-level split
		height = 10,

		hide = false
	}, spec.config.message.history_winconfig or {});

	if message.history_window and vim.api.nvim_win_is_valid(message.history_window) then
		pcall(vim.api.nvim_win_set_config, message.history_window, window_config);
	else
		message.history_window = vim.api.nvim_open_win(message.history_buffer, true, window_config);
		vim.api.nvim_win_set_var(message.history_window, "ui_window", true);
	end

	vim.api.nvim_set_current_win(message.history_window);

	utils.set("w", message.history_window, "statuscolumn", "%!v:lua.__ui_statuscolumn()");

	utils.set("w", message.history_window, "wrap", true);
	utils.set("w", message.history_window, "linebreak", true);

	vim.api.nvim__redraw({
		flush = true,

		win = message.history_window,
		statuscolumn = true,
	});
	vim.g.__ui_history = false;

	---|fE
end

------------------------------------------------------------------------------

message.__showcmd = function (content)
	---|fS

	content = content or vim.g.__ui_showcmd or {};

	message.__prepare();
	vim.g.__ui_showcmd = content;

	local window_config = vim.tbl_extend("keep", spec.config.message.showcmd_winconfig or {}, {
		relative = "editor",

		row = vim.o.lines - (vim.o.cmdheight + message.__get_cmdline_offset() + 2) ,
		col = 0,

		width = 10,
		height = 1,

		border = "none",

		zindex = 80,
		hide = false
	});

	local text, extmarks = utils.process_content(content);

	if #text == 0 or text[1] == "" then
		-- Close the window if there is no text.
		vim.g.__ui_showcmd = {};
		window_config.hide = true;

		pcall(vim.api.nvim_win_set_config, message.show_window, window_config);
		return;
	elseif spec.config.message.showcmd.modifier then
		local modifier = utils.eval(spec.config.message.showcmd.modifier, content, text, extmarks);

		if type(modifier) == "table" then
			text = modifier.lines or text;
			extmarks = modifier.extmarks or extmarks;
		end
	end

	--- Change window width.
	window_config.width = math.min(
		vim.fn.strdisplaywidth(text[1]),
		spec.config.message.showcmd.max_width or 0
	);

	vim.api.nvim_buf_clear_namespace(message.show_buffer, message.namespace, 0, -1);
	vim.api.nvim_buf_set_lines(message.show_buffer, 0, -1, false, text);

	for l, line in ipairs(extmarks) do
		for _, ext in ipairs(line) do
			if ext[3] == "" then
				goto continue;
			end

			vim.api.nvim_buf_set_extmark(message.show_buffer, message.namespace, l - 1, ext[1], {
				end_col = ext[2],
				hl_group = ext[3]
			});

		    ::continue::
		end
	end

	if message.show_window and vim.api.nvim_win_is_valid(message.show_window) then
		vim.api.nvim_win_set_config(message.show_window, window_config);
	else
		message.show_window = vim.api.nvim_open_win(message.show_buffer, false, window_config);
		vim.api.nvim_win_set_var(message.show_window, "ui_window", true);

		--- Always horizontally center the cursor.
		--- We can't dynamically set this without bombing users with
		--- `OptionSet` events.
		utils.set("w", message.show_window, "sidescrolloff", 999);
	end

	-- Use display width instead of byte length as there are
	-- multi-byte characters.
	-- If all else fails, `pcall()` should save us.
	pcall(vim.api.nvim_win_set_cursor, message.show_window, {
		1, math.floor(window_config.width / 2)
	});

	vim.api.nvim__redraw({
		flush = true,
		win = message.show_window
	});

	---|fE
end

------------------------------------------------------------------------------

---@param kind ui.message.kind
---@param content ui.message.fragment[]
---@param replace_last boolean
---@param add_to_history boolean
message.msg_show = function (kind, content, replace_last, add_to_history)
	---|fS

	if kind == "confirm" then
		-- Confirm messages need to be
		-- handled first.

		log.assert(
			"ui/message.lua → __confirm",
			pcall(message.__confirm, {
				kind = kind,
				content = content,
			})
		);
	elseif message.ui_attached == false then
		-- Cache messages if the UI hasn't been attached
		-- to yet.
		message.cache(kind, content, replace_last, add_to_history);
	elseif kind == "search_count" then
		message.__replace(kind, content, add_to_history);
	elseif kind == "return_prompt" then
		--- Hit `<ESC>` on hit-enter prompts.
		--- or else we get stuck.
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<ESC>", true, false, true), "n", false);
	elseif replace_last and vim.tbl_isempty(message.visible) == false then
		message.__replace(kind, content, add_to_history);
	else
		message.__add(kind, content, add_to_history)
	end

	---|fE
end

---@param entries ( ui.message.fragment[] )[]
message.msg_history_show = function (entries)
	---|fS

	-- Escape hit-enter from opening messages.
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false);

	log.assert(
		"ui/message.lua → history_show",
		pcall(message.__history, entries)
	);

	---|fE
end

-- message.msg_showmode = function (content)
-- 	table.insert(log.entries, vim.inspect(content))
-- end

message.msg_showcmd = function (content)
	message.__showcmd(content);
end

message.msg_clear = function ()
	---|fS

	if not vim.g.__confirm_keys or #vim.g.__confirm_keys == 0 then
		return;
	end

	for k, v in pairs(message.visible) do
		v.timer:stop();
		message.__remove(k);
	end

	message.__render();

	---|fE
end

------------------------------------------------------------------------------

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
			message.__list_resize();

			if vim.g.__ui_showcmd then
				message.__showcmd(vim.g.__ui_showcmd);
			end

			message.__render();
		end
	});

	vim.api.nvim_create_autocmd("TabLeave", {
		callback = function ()
			pcall(vim.api.nvim_win_close, message.msg_window, true);
			pcall(vim.api.nvim_win_close, message.show_window, true);

			message.msg_window = nil;
			message.show_window = nil;
		end
	});

	vim.api.nvim_create_autocmd({
		"VimEnter",
		"TabEnter"
	}, {
		callback = function ()
			message.__render();
		end
	});

	---|fE
end

return message;

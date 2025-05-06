--- Custom message for
--- Neovim.
local message = {};

local log = require("ui.log");
local spec = require("ui.spec");
local utils = require("ui.utils");

------------------------------------------------------------------------------

---@type integer Namespace for decorations in messages.
message.namespace = vim.api.nvim_create_namespace("ui.message")

---@type integer, integer[] Buffer & window for messages.
message.msg_buffer, message.msg_window = nil, {};

---@type integer, integer[] Buffer & window for showing larger messages.
message.list_buffer, message.list_window = nil, {};

---@type integer, integer[] Buffer & window for confirmation messages.
message.confirm_buffer, message.confirm_window = nil, {};

---@type integer, integer[] Buffer & window for message history.
message.history_buffer, message.history_window = nil, {};

---@type integer, integer[] Buffer & window for showmode.
message.show_buffer, message.show_window = nil, {};

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
	local tab = vim.api.nvim_get_current_tabpage();
	local win = vim.g.statusline_winid;

	if win ~= message.msg_window[tab] and win ~= message.history_window[tab] then
		-- Wrong window.
		return "";
	elseif not message.decorations and not message.history_decorations then
		-- Decorations not available.
		return "";
	end

	---@type integer Current line-number(0-indexed).
	local lnum = vim.v.lnum - 1;

	for _, entry in ipairs(win == message.history_window[tab] and (message.history_decorations or {}) or (message.decorations or {})) do
		if lnum >= entry.from and lnum <= entry.to then
			if lnum == entry.from and vim.v.virtnum == 0 then
				return utils.to_statuscolumn(entry.icon);
			elseif lnum == entry.to and vim.v.virtnum == 0 then
				return utils.to_statuscolumn(
					entry.tail or entry.padding or utils.strip_text(entry.icon)
				);
			else
				return utils.to_statuscolumn(
					entry.padding or utils.strip_text(entry.icon)
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

vim.api.nvim_create_autocmd("UIEnter", {
	callback = function ()
		message.ui_attached = true;

		for _, item in ipairs(message.ui_echo) do
			message.__add(item.kind, item.content);
		end
	end
});

------------------------------------------------------------------------------

--- Prepares various window & buffers.
message.__prepare = function ()
	---|fS

	---@type integer Current tab ID.
	local tab = vim.api.nvim_get_current_tabpage();

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

	if not message.msg_window[tab] or vim.api.nvim_win_is_valid(message.msg_window[tab]) == false then
		message.msg_window[tab] = vim.api.nvim_open_win(message.msg_buffer, false, win_config);
		vim.api.nvim_win_set_var(message.msg_window[tab], "ui_window", true);

		utils.set("w", message.msg_window[tab], "numberwidth", 1);
		utils.set("w", message.msg_window[tab], "statuscolumn", "%!v:lua.__ui_statuscolumn()");
	end

	----------

	if not message.list_buffer or vim.api.nvim_buf_is_valid(message.list_buffer) == false then
		message.list_buffer = vim.api.nvim_create_buf(false, true);
	end

	if not message.list_window[tab] or vim.api.nvim_win_is_valid(message.list_window[tab]) == false then
		message.list_window[tab] = vim.api.nvim_open_win(message.list_buffer, false, win_config);
		vim.api.nvim_win_set_var(message.list_window[tab], "ui_window", true);
	end

	----------

	if not message.confirm_buffer or vim.api.nvim_buf_is_valid(message.confirm_buffer) == false then
		message.confirm_buffer = vim.api.nvim_create_buf(false, true);
	end

	if not message.confirm_window[tab] or vim.api.nvim_win_is_valid(message.confirm_window[tab]) == false then
		message.confirm_window[tab] = vim.api.nvim_open_win(message.confirm_buffer, false, win_config);
		vim.api.nvim_win_set_var(message.confirm_window[tab], "ui_window", true);
	end

	----------

	if not message.history_buffer or vim.api.nvim_buf_is_valid(message.history_buffer) == false then
		message.history_buffer = vim.api.nvim_create_buf(false, true);
	end

	if not message.history_window[tab] or vim.api.nvim_win_is_valid(message.history_window[tab]) == false then
		message.history_window[tab] = vim.api.nvim_open_win(message.history_buffer, false, win_config);
		vim.api.nvim_win_set_var(message.history_window[tab], "ui_window", true);

		utils.set("w", message.history_window[tab], "numberwidth", 1);
		utils.set("w", message.history_window[tab], "statuscolumn", "%!v:lua.__ui_statuscolumn()");
	end

	----------

	if not message.show_buffer or vim.api.nvim_buf_is_valid(message.show_buffer) == false then
		message.show_buffer = vim.api.nvim_create_buf(false, true);
	end

	if not message.show_window[tab] or vim.api.nvim_win_is_valid(message.show_window[tab]) == false then
		message.show_window[tab] = vim.api.nvim_open_win(message.show_buffer, false, win_config);
		vim.api.nvim_win_set_var(message.show_window[tab], "ui_window", true);

		utils.set("w", message.show_window[tab], "sidescrolloff", 0);
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

	local timer = vim.uv.new_timer();

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
message.__add = function (kind, content)
	---|fS

	if message.ui_attached == false then
		table.insert(message.ui_echo, {
			kind = kind,
			content = content
		});
		return;
	elseif kind == "" and vim.tbl_isempty(message.visible) == false then
		local IDs = vim.tbl_keys(message.visible);
		table.sort(IDs);

		-- Last visible message.
		local last = message.visible[IDs[#IDs]];

		if vim.deep_equal(last.content, content) then
			-- BUG, Vim resends old message on redraw.
			-- Last message will be replaced with this
			-- one.
			--
			-- The second message has the wrong kind so
			-- we use the original kind.

			message.__replace(last.kind, content);
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
		local is_list, add_to_history = spec.is_list(kind, content);
		local max_lines = spec.config.message.max_lines or math.floor(vim.o.lines * 0.5);

		if is_list == true or #lines > max_lines then
			-- If a list message for some reason gets here then
			-- we redirect it.
			log.assert(
				"ui/message.lua → replace_list",
				pcall(message.__list, {
					kind = kind,
					content = content
				})
			);

			if add_to_history or #lines > max_lines then
				-- Long message that aren't actually
				-- list message should be added to history.
				message.history[message.id] = {
					kind = kind,
					content = content
				};

				message.id = message.id + 1;
			end

			return;
		end

		local current_id = message.id;

		---@type ui.message.style__static
		local style = spec.get_msg_style({ kind = kind, content = content }, lines, {}) or {};
		local duration = math.min(
			style.duration or 5000,
			spec.config.message.max_duration or 5000
		);

		-- Store the message in history & visible
		-- message table.
		message.history[message.id] = {
			kind = kind,
			content = content
		};
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
message.__replace = function (kind, content)
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
		local is_list, add_to_history = spec.is_list(kind, content);
		local max_lines = spec.config.message.max_lines or math.floor(vim.o.lines * 0.5);

		if is_list == true or #lines > max_lines then
			-- If a list message for some reason gets here then
			-- we redirect it.
			log.assert(
				"ui/message.lua → replace_list",
				pcall(message.__list, {
					kind = kind,
					content = content
				})
			);

			if add_to_history or #lines > max_lines then
				-- Long message that aren't actually
				-- list message should be added to history.
				local last = message.visible[keys[#keys]];

				if last then
					message.history[last] = {
						kind = kind,
						content = content
					};
				else
					message.history[message.id] = {
						kind = kind,
						content = content
					};

					message.id = message.id + 1;
				end
			end

			return;
		end

		if #keys == 0 then
			-- No visible message available.
			message.__add(kind, content);
			return;
		end

		local last = message.visible[keys[#keys]];

		if not last then
			-- Current messages `kind` doesn't match
			-- the previous messages `kind`.
			message.__add(kind, content);
			return;
		end

		last.kind = kind;
		last.content = content;

		last.timer:stop();

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

		---@type integer
		local tab = vim.api.nvim_get_current_tabpage();

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

		if message.confirm_window[tab] and vim.api.nvim_win_is_valid(message.confirm_window[tab]) then
			vim.api.nvim_win_set_config(message.confirm_window[tab], window_config);
		else
			message.confirm_window[tab] = vim.api.nvim_open_win(message.confirm_buffer, false, window_config);
			vim.api.nvim_win_set_var(message.confirm_window[tab], "ui_window", true);
		end

		utils.set("w", message.confirm_window[tab], "wrap", true);
		utils.set("w", message.confirm_window[tab], "linebreak", true);

		if config.winhl then
			utils.set("w", message.confirm_window[tab], "winhl", config.winhl);
		end

		--- Auto hide on next key press.
		vim.on_key(function (key)
			if vim.list_contains(vim.g.__confirm_keys or {}, string.lower(key)) == false then
				return;
			end

			pcall(vim.api.nvim_win_set_config, message.confirm_window[tab], { hide = true });
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

	--- All logic must be run outside of
	--- fast event.
	vim.schedule(function ()
		vim.g.__ui_list_msg = obj;

		local lines, exts = utils.process_content(obj.content);

		message.__prepare();

		---@type ui.message.list__static
		local config = spec.get_listmsg_style(obj, lines, exts);

		if config.modifier then
			lines = config.modifier.lines or lines;
			exts = config.modifier.extmarks or exts;
		end

		vim.api.nvim_buf_set_keymap(message.list_buffer, "n", "q", "", {
			callback = function ()
				---@type integer
				local tab = vim.api.nvim_get_current_tabpage();

				vim.api.nvim_set_current_win(
					utils.last_win()
				);
				vim.api.nvim_win_set_config(message.list_window[tab], {
					relative = "editor",

					row = 0, col = 0,
					width = 1, height = 1,

					hide = true
				});

				vim.g.__ui_list_msg = nil;
			end
		});

		---@type integer
		local W = math.min(utils.max_len(lines), math.floor(vim.o.columns * 0.75));
		---@type integer
		local H = math.min(utils.wrapped_height(lines, W), vim.o.lines - 2);

		---@type integer
		local tab = vim.api.nvim_get_current_tabpage();

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

		if message.list_window[tab] and vim.api.nvim_win_is_valid(message.list_window[tab]) then
			vim.api.nvim_win_set_config(message.list_window[tab], window_config);
		else
			message.list_window[tab] = vim.api.nvim_open_win(message.list_buffer, false, window_config);
			vim.api.nvim_win_set_var(message.list_window[tab], "ui_window", true);
		end

		vim.api.nvim_set_current_win(message.list_window[tab]);

		utils.set("w", message.list_window[tab], "wrap", true);
		utils.set("w", message.list_window[tab], "linebreak", true);

		if config.winhl then
			utils.set("w", message.list_window[tab], "winhl", config.winhl);
		end
	end);

	---|fE
end

--- Hides the message window.
message.__hide = function ()
	---|fS

	local keys = vim.tbl_keys(message.visible);
	if #keys ~= 0 then return; end

	---@type integer
	local tab = vim.api.nvim_get_current_tabpage();

	pcall(vim.api.nvim_win_set_config, message.msg_window[tab], { hide = true });

	---|fE
end

message.__get_cmdline_offset = function ()
	local cmdline_offset = 0
	if vim.g.__ui_cmd_height and vim.g.__ui_cmd_height > 0 then
		cmdline_offset = vim.g.__ui_cmd_height + spec.config.cmdline.row_offset - 1
	end
	return cmdline_offset
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

	---@type integer
	local tab = vim.api.nvim_get_current_tabpage();

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

	if message.msg_window[tab] and vim.api.nvim_win_is_valid(message.msg_window[tab]) then
		vim.api.nvim_win_set_config(message.msg_window[tab], window_config);
	else
		message.msg_window[tab] = vim.api.nvim_open_win(message.msg_buffer, false, window_config);
		vim.api.nvim_win_set_var(message.msg_window[tab], "ui_window", true);
	end

	utils.set("w", message.msg_window[tab], "winhl", "Normal:Normal");
	utils.set("w", message.msg_window[tab], "statuscolumn", "%!v:lua.__ui_statuscolumn()");

	utils.set("w", message.msg_window[tab], "wrap", true);
	utils.set("w", message.msg_window[tab], "linebreak", true);

	vim.api.nvim__redraw({
		flush = true,
		-- BUG, Visual artifacts are shown if the statuscolumn
		-- is updated repeatedly.
		-- Solution: Update when the decoration size changes.
		statuscolumn = last_decor_size ~= decor_size,

		win = message.msg_window[tab]
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

	---|fS

	vim.api.nvim_buf_set_keymap(message.history_buffer, "n", "t", "", {
		desc = "Toggles between `vim` and `ui.nvim`'s message history.",
		callback = function ()
			vim.g.__ui_history_pref = vim.g.__ui_history_pref == "vim" and "ui" or "vim";
			message.__history(entries);
		end
	});

	vim.api.nvim_buf_set_keymap(message.history_buffer, "n", "q", "", {
		desc = "Quits message window.",
		callback = function ()
			---|fS

			---@type integer
			local tab = vim.api.nvim_get_current_tabpage();

			-- Instead of closing the window, we hide it.
			--
			-- Only floating windows can be hidden so we
			-- turn it into a floating window.
			vim.api.nvim_set_current_win(
				utils.last_win()
			);
			log.assert(
				"ui/message.lua → history_quit",
				pcall(vim.api.nvim_win_set_config, message.history_window[tab], {
					relative = "editor",

					row = 0, col = 0,
					width = 1, height = 1,

					hide = true
				})
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

	vim.api.nvim_buf_clear_namespace(message.history_buffer, message.namespace, 0, -1);
	vim.api.nvim_buf_set_lines(message.history_buffer, 0, -1, false, lines);

	---|fS

	-- Add keymap hints
	vim.api.nvim_buf_set_extmark(message.history_buffer, message.namespace, 0, 0, {
		virt_text_pos = "right_align",
		virt_text = {
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

	---@type integer
	local tab = vim.api.nvim_get_current_tabpage();

	local window_config = vim.tbl_extend("force", {
		split = "below",
		win = -1, -- creates top-level split
		height = 10,

		hide = false
	}, spec.config.message.history_winconfig or {});

	if message.history_window[tab] and vim.api.nvim_win_is_valid(message.history_window[tab]) then
		vim.api.nvim_win_set_config(message.history_window[tab], window_config);
	else
		message.history_window[tab] = vim.api.nvim_open_win(message.history_buffer, true, window_config);
		vim.api.nvim_win_set_var(message.history_window[tab], "ui_window", true);
	end

	vim.api.nvim_set_current_win(message.history_window[tab]);

	utils.set("w", message.history_window[tab], "statuscolumn", "%!v:lua.__ui_statuscolumn()");

	utils.set("w", message.history_window[tab], "wrap", true);
	utils.set("w", message.history_window[tab], "linebreak", true);

	vim.api.nvim__redraw({
		flush = true,

		win = message.history_window[tab],
		statuscolumn = true,
	});
	vim.g.__ui_history = false;

	---|fE
end

------------------------------------------------------------------------------

message.__showcmd = function (content)
	---|fS

	content = content or vim.g.__ui_showcmd or {};

	---@type integer
	local tab = vim.api.nvim_get_current_tabpage();
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

		pcall(vim.api.nvim_win_set_config, message.show_window[tab], window_config);
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

	if message.show_window[tab] and vim.api.nvim_win_is_valid(message.show_window[tab]) then
		vim.api.nvim_win_set_config(message.show_window[tab], window_config);
	else
		message.show_window[tab] = vim.api.nvim_open_win(message.show_buffer, false, window_config);
		vim.api.nvim_win_set_var(message.show_window[tab], "ui_window", true);

		--- Always horizontally center the cursor.
		--- We can't dynamically set this without bombing users with
		--- `OptionSet` events.
		utils.set("w", message.show_window[tab], "sidescrolloff", 999);
	end

	-- Use display width instead of byte length as there are
	-- multi-byte characters.
	-- If all else fails, `pcall()` should save us.
	pcall(vim.api.nvim_win_set_cursor, message.show_window[tab], {
		1, math.floor(window_config.width / 2)
	});

	vim.api.nvim__redraw({
		flush = true,
		win = message.show_window[tab]
	});

	---|fE
end

------------------------------------------------------------------------------

---@param kind ui.message.kind
---@param content ui.message.fragment[]
---@param replace_last boolean
message.msg_show = function (kind, content, replace_last)
	---|fS

	if kind == "confirm" then
		log.assert(
			"ui/message.lua → __confirm",
			pcall(message.__confirm, {
				kind = kind,
				content = content,
			})
		);
	elseif kind == "search_count" then
		--- Do not handle search count as messages.
		message.__replace(kind, content);
	elseif kind == "return_prompt" then
		--- Hit `<ESC>` on hit-enter prompts.
		--- or else we get stuck.
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<ESC>", true, false, true), "n", false);
	elseif replace_last and vim.tbl_isempty(message.visible) == false then
		message.__replace(kind, content);
	else
		message.__add(kind, content)
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

	vim.api.nvim_create_autocmd("VimEnter", {
		callback = function ()
			message.__prepare();
		end
	});

	vim.api.nvim_create_autocmd("WinClosed", {
		callback = function ()
			local tab = vim.api.nvim_get_current_tabpage()
			if message.list_window[tab] == vim.api.nvim_get_current_win() then
				message.list_window[tab] = nil;
				vim.g.__ui_list_msg = nil;
			end
		end
	})

	vim.api.nvim_create_autocmd("VimResized", {
		callback = function ()
			if vim.g.__ui_confirm_msg then
				--- If a confirmation window is active,
				--- redraw it.
				message.__confirm(vim.g.__ui_confirm_msg);
			end

			if vim.g.__ui_list_msg then
				--- If a list message window is active,
				--- redraw it.
				message.__list(vim.g.__ui_list_msg);
			end

			if vim.g.__ui_showcmd then
				message.__showcmd(vim.g.__ui_showcmd);
			end

			message.__render();
		end
	});

	vim.api.nvim_create_autocmd("TabEnter", {
		callback = function ()
			if vim.g.__ui_confirm_msg then
				--- If a confirmation window is active,
				--- redraw it.
				message.__confirm(vim.g.__ui_confirm_msg);
			end

			message.__render();
		end
	});

	---|fE
end

return message;

--- Custom message for
--- Neovim.
local message = {};

local log = require("ui.log");
local spec = require("ui.spec");
local utils = require("ui.utils");

---@type "vim" | "ui" Message history source preference.
vim.g.__ui_history_pref = "vim";

------------------------------------------------------------------------------

---@type integer Namespace for decorations in messages.
message.namespace = vim.api.nvim_create_namespace("ui.message")

---@type integer, integer[] Buffer & window for messages.
message.msg_buffer, message.msg_window = nil, {};

---@type integer, integer[] Buffer & window for showing larger messages.
message.list_buffer, message.list_window = nil, {};

---@type integer, integer[] Buffer & window for showing stuff.
message.confirm_buffer, message.confirm_window = nil, {};

---@type integer, integer[] Buffer & window for showing stuff.
message.history_buffer, message.history_window = nil, {};

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
		hide = true
	};

	if not message.msg_buffer or vim.api.nvim_buf_is_valid(message.msg_buffer) == false then
		message.msg_buffer = vim.api.nvim_create_buf(false, true);
	end

	if not message.msg_window[tab] or vim.api.nvim_win_is_valid(message.msg_window[tab]) == false then
		message.msg_window[tab] = vim.api.nvim_open_win(message.msg_buffer, false, win_config);
		vim.api.nvim_win_set_var(message.msg_window[tab], "ui_window", true);

		vim.wo[message.msg_window[tab]].numberwidth = 1;
		vim.wo[message.msg_window[tab]].statuscolumn = "%!v:lua.__ui_statuscolumn()";
	end

	if not message.list_buffer or vim.api.nvim_buf_is_valid(message.list_buffer) == false then
		message.list_buffer = vim.api.nvim_create_buf(false, true);
	end

	if not message.list_window[tab] or vim.api.nvim_win_is_valid(message.list_window[tab]) == false then
		message.list_window[tab] = vim.api.nvim_open_win(message.list_buffer, false, win_config);
		vim.api.nvim_win_set_var(message.list_window[tab], "ui_window", true);
	end

	if not message.confirm_buffer or vim.api.nvim_buf_is_valid(message.confirm_buffer) == false then
		message.confirm_buffer = vim.api.nvim_create_buf(false, true);
	end

	if not message.confirm_window[tab] or vim.api.nvim_win_is_valid(message.confirm_window[tab]) == false then
		message.confirm_window[tab] = vim.api.nvim_open_win(message.confirm_buffer, false, win_config);
		vim.api.nvim_win_set_var(message.confirm_window[tab], "ui_window", true);
	end

	if not message.history_buffer or vim.api.nvim_buf_is_valid(message.history_buffer) == false then
		message.history_buffer = vim.api.nvim_create_buf(false, true);
	end

	if not message.history_window[tab] or vim.api.nvim_win_is_valid(message.history_window[tab]) == false then
		message.history_window[tab] = vim.api.nvim_open_win(message.history_buffer, false, win_config);
		vim.api.nvim_win_set_var(message.history_window[tab], "ui_window", true);

		vim.wo[message.history_window[tab]].numberwidth = 1;
		vim.wo[message.history_window[tab]].statuscolumn = "%!v:lua.__ui_statuscolumn()";
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
	end

	vim.schedule(function ()
		---|fS

		---@type boolean Should this message be ignored?
		local condition = utils.eval(spec.config.message.ignore, kind, content);

		if condition == true then
			return;
		end

		if spec.is_list({ kind = kind, content = content }) == true then
			-- If the message is a list message,
			-- pass it to the list renderer.
			log.assert(
				pcall(message.__list, {
					kind = kind,
					content = content
				})
			);
			return;
		end

		local current_id = message.id;
		local lines = utils.to_lines(content);

		---@type ui.message.style__static
		local style = spec.get_msg_style({ kind = kind, content = content }, lines, {}) or {};
		local duration = style.duration or 600;

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

		if spec.is_list({ kind = kind, content = content }) == true then
			-- If a list message for some reason gets here then
			-- we redirect it.
			log.assert(
				pcall(message.__list, {
					kind = kind,
					content = content
				})
			);
			return;
		end

		---@type integer
		local keys = vim.tbl_keys(message.visible);

		if #keys == 0 then
			-- No visible message available.
			message.__add(kind, content);
			return;
		end

		local last = message.visible[keys[#keys]];

		if not last or last.kind ~= kind then
			-- Current messages `kind` doesn't match
			-- the previous messages `kind`.
			message.__add(kind, content);
			return;
		end

		last.content = content;
		last.timer:stop();

		local lines = utils.to_lines(content);

		---@type ui.message.style__static
		local style = spec.get_msg_style({ kind = kind, content = content }, lines, {}) or {};
		local duration = style.duration or 600;

		last.timer:start(duration, 0, vim.schedule_wrap(function ()
			message.__remove(keys[#keys]);
		end));

		log.assert(
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

		vim.wo[message.confirm_window[tab]].wrap = true;
		vim.wo[message.confirm_window[tab]].linebreak = true;

		if config.winhl then
			vim.wo[message.confirm_window[tab]].winhl = config.winhl;
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
		local W = math.min(utils.max_len(lines), math.floor(vim.o.columns * 0.5));
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
			hide = false
		}, spec.config.message.list_winconfig or {});

		vim.api.nvim_buf_clear_namespace(message.list_buffer, message.namespace, 0, -1);
		vim.api.nvim_buf_set_lines(message.list_buffer, 0, -1, false, lines);

		for l, line in ipairs(exts) do
			for _, ext in ipairs(line) do
				log.assert(
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

		vim.wo[message.list_window[tab]].wrap = true;
		vim.wo[message.list_window[tab]].linebreak = true;

		if config.winhl then
			vim.wo[message.list_window[tab]].winhl = config.winhl;
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

		row = vim.o.lines - (vim.o.cmdheight + (vim.g.__ui_cmd_height or 0) + 1) - utils.wrapped_height(lines, W),
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

	vim.wo[message.msg_window[tab]].statuscolumn = "%!v:lua.__ui_statuscolumn()";
	vim.wo[message.msg_window[tab]].winhl = "Normal:Normal";

	vim.wo[message.msg_window[tab]].wrap = true;
	vim.wo[message.msg_window[tab]].linebreak = true;

	---|fE
end

--- Loads history in a window.
---@param entries ( ui.message.fragment[] )[]
message.__history = function (entries)
	---|fS

	vim.g.__ui_history_pref = vim.g.__ui_history_pref or "vim";
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

	vim.wo[message.history_window[tab]].statuscolumn = "%!v:lua.__ui_statuscolumn()";

	vim.wo[message.history_window[tab]].wrap = true;
	vim.wo[message.history_window[tab]].linebreak = true;

	vim.api.nvim__redraw({
		flush = true,

		win = message.history_window[tab],
		statuscolumn = true,
	});
	vim.g.__ui_history = false;

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
			pcall(message.__confirm, {
				kind = kind,
				content = content,
			})
		);
	elseif kind == "search_count" then
		--- Do not handle search count as messages.
		return;
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
		pcall(message.__history, entries)
	);

	---|fE
end

-- message.msg_showmode = function (content)
-- 	table.insert(log.entries, vim.inspect(content))
-- end

-- message.msg_showcmd = function (content)
-- 	table.insert(log.entries, vim.inspect(content))
-- end

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

	if not message[event] then
		return;
	end

	log.assert(
		pcall(message[event], ...)
	);

	---|fE
end

message.setup = function ()
	---|fS

	message.__prepare();

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

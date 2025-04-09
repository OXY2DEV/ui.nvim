--- Custom message for
--- Neovim.
local message = {};

local log = require("ui.log");
local spec = require("ui.spec");
local utils = require("ui.utils");

------------------------------------------------------------------------------

---@type integer
message.namespace = vim.api.nvim_create_namespace("ui.message")

---@type integer, integer Buffer & window for messages.
message.msg_buffer, message.msg_window = nil, nil;

---@type integer, integer Buffer & window for showing stuff.
-- message.show_buffer, message.show_window = nil, nil;

---@type integer, integer Buffer & window for showing stuff.
message.confirm_buffer, message.confirm_window = nil, nil;

---@type integer, integer Buffer & window for showing stuff.
message.history_buffer, message.history_window = nil, nil;

message.state = {};

message.get_state = function (key, fallback)
	return message.state[key] ~= nil and message.state[key] or fallback;
end

message.set_state = function (new_state)
	message.state = vim.tbl_extend("force", message.state or {}, new_state);
end

message.id = 2000;
message.last = nil;

message.history = {};

message.visible = {};

------------------------------------------------------------------------------

message.__prepare = function ()
	local win_config = {
			relative = "editor",

			row = 0, col = 0,
			width = 1, height = 1,

			style = "minimal",
			hide = true
	};

	if not message.msg_buffer or vim.api.nvim_buf_is_valid(message.msg_buffer) == false then
		message.msg_buffer = vim.api.nvim_create_buf(false, true);
	end

	if not message.msg_window or vim.api.nvim_win_is_valid(message.msg_window) == false then
		message.msg_window = vim.api.nvim_open_win(message.msg_buffer, false, win_config);
	end

	-- if not message.show_buffer or vim.api.nvim_buf_is_valid(message.show_buffer) == false then
	-- 	message.show_buffer = vim.api.nvim_create_buf(false, true);
	-- end
	--
	-- if not message.show_window or vim.api.nvim_win_is_valid(message.show_window) == false then
	-- 	message.show_window = vim.api.nvim_open_win(message.show_buffer, false, win_config);
	-- end

	if not message.confirm_buffer or vim.api.nvim_buf_is_valid(message.confirm_buffer) == false then
		message.confirm_buffer = vim.api.nvim_create_buf(false, true);
	end

	if not message.confirm_window or vim.api.nvim_win_is_valid(message.confirm_window) == false then
		message.confirm_window = vim.api.nvim_open_win(message.confirm_buffer, false, win_config);
	end

	if not message.history_buffer or vim.api.nvim_buf_is_valid(message.history_buffer) == false then
		message.history_buffer = vim.api.nvim_create_buf(false, true);
	end

	if not message.history_window or vim.api.nvim_win_is_valid(message.history_window) == false then
		message.history_window = vim.api.nvim_open_win(message.history_buffer, false, win_config);
	end
end

message.timer = function (callback, duration, interval)
	local timer = vim.uv.new_timer();

	if interval then
		timer:start(0, duration, vim.schedule_wrap(callback));
	else
		timer:start(duration, 0, vim.schedule_wrap(callback));
	end

	return timer;
end

message.__remove = function (id)
	if message.visible[id] then
		message.visible[id] = nil;

		vim.schedule(function ()
			local _, e = pcall(message.__render);
			table.insert(log.entries, e)
		end)
	end
end

------------------------------------------------------------------------------

--- Confirmation message.
---@param obj table
message.__confirm = function (obj)
	--- All logic must be run outside of
	--- fast event.
	vim.schedule(function ()
		vim.g.__confirm_msg = obj;
		local lines, exts = utils.process_content(obj.content);

		message.__prepare();
		local config = spec.get_confirm_config(obj, lines);

		if config.modifier then
			lines = config.modifier.lines or lines;
			exts = config.modifier.extmarks or exts;
		end

		local window_config = {
			relative = "editor",

			row = config.row or math.ceil((vim.o.lines - #lines) / 2),
			col = config.col or math.ceil((vim.o.columns - utils.max_len(lines)) / 2),

			width = config.width or utils.max_len(lines),
			height = config.height or #lines,

			border = config.border,
			style = "minimal",

			hide = false
		};

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

		if message.confirm_window and vim.api.nvim_win_is_valid(message.confirm_window) then
			vim.api.nvim_win_set_config(message.confirm_window, window_config);
		else
			message.confirm_window = vim.api.nvim_open_win(message.confirm_buffer, false, window_config);
		end

		vim.wo[message.confirm_window].wrap = true;
		vim.wo[message.confirm_window].linebreak = true;

		if config.winhl then
			vim.wo[message.confirm_window].winhl = config.winhl;
		end

		--- Auto hide on next keypress.
		vim.on_key(function (key)
			if vim.list_contains(vim.g.__confirm_keys or {}, key) == false then
				return;
			end

			pcall(vim.api.nvim_win_set_config, message.confirm_window, { hide = true });
			vim.on_key(nil, message.namespace);

			vim.g.__confirm_msg = nil;
		end, message.namespace);
	end)
end

message.__hide = function ()
	local keys = vim.tbl_keys(message.visible);
	if #keys ~= 0 then return; end

	pcall(vim.api.nvim_win_set_config, message.msg_window, { hide = true });
end

message.__render = function ()
	local keys = vim.tbl_keys(message.visible);

	if #keys == 0 then
		message.__hide();
		return;
	end

	message.__prepare();
	local lines, exts = {}, {};

	for _, key in ipairs(keys) do
		local value = message.visible[key];
		local m_lines, m_exts = utils.process_content(value.content);

	table.insert(log.entries, vim.inspect(value.content))

		lines = vim.list_extend(lines, m_lines)
		exts = vim.list_extend(exts, m_exts)
	end

	vim.api.nvim_buf_clear_namespace(message.msg_buffer, message.namespace, 0, -1);
	vim.api.nvim_buf_set_lines(message.msg_buffer, 0, -1, false, lines);

	local W = 5;

	for l, line in ipairs(exts) do
		local text = lines[l];

		if vim.fn.strchars(text) > W then
			W = vim.fn.strchars(text);
		end

		for _, ext in ipairs(line) do
			vim.api.nvim_buf_set_extmark(message.msg_buffer, message.namespace, l - 1, ext[1], {
				end_col = ext[2],
				hl_group = ext[3]
			});
		end
	end

	local window_config = {
		relative = "editor",

		row = vim.o.lines - (vim.o.cmdheight + 1) - math.min(#lines, 5),
		col = vim.o.columns,

		width = W,
		height = math.min(#lines, 5),

		style = "minimal",

		hide = false
	}

	if message.msg_window and vim.api.nvim_win_is_valid(message.msg_window) then
		vim.api.nvim_win_set_config(message.msg_window, window_config);
	else
		message.msg_window = vim.api.nvim_open_win(message.msg_buffer, false, window_config);
	end

	vim.wo[message.msg_window].winhl = "Normal:Normal";

	vim.wo[message.msg_window].wrap = true;
	vim.wo[message.msg_window].linebreak = true;
end

message.__history = function (entries)
	vim.g.__history_src = vim.g.__history_src or "vim";
	message.__prepare();

	vim.api.nvim_buf_set_keymap(message.history_buffer, "n", "t", "", {
		callback = function ()
			vim.g.__history_src = vim.g.__history_src == "vim" and "internal" or "vim";
			message.__history(entries);
		end
	});

	local lines, exts = {}, {};

	if vim.g.__history_src == "vim" and entries then
		for _, entry in ipairs(entries) do
			local _lines, _exts = utils.process_content(entry[2]);

			lines = vim.list_extend(lines, _lines);
			exts = vim.list_extend(exts, _exts);
		end
	else
		local keys = vim.tbl_keys(message.history);
		table.sort(keys);

		for _, key in ipairs(keys) do
			local entry = message.history[key];
			local _lines, _exts = utils.process_content(entry.content);

			lines = vim.list_extend(lines, _lines);
			exts = vim.list_extend(exts, _exts);
		end
	end

	vim.api.nvim_buf_clear_namespace(message.history_buffer, message.namespace, 0, -1);
	vim.api.nvim_buf_set_lines(message.history_buffer, 0, -1, false, lines);

	for l, line in ipairs(exts) do
		for _, ext in ipairs(line) do
			vim.api.nvim_buf_set_extmark(message.history_buffer, message.namespace, l - 1, ext[1], {
				end_col = ext[2],
				hl_group = ext[3]
			});
		end
	end

	local window_config = {
		split = "below",
		height = 10,

		style = "minimal",

		hide = false
	}

	if message.history_window and vim.api.nvim_win_is_valid(message.history_window) then
		vim.api.nvim_win_set_config(message.history_window, window_config);
		vim.api.nvim_set_current_win(message.history_window);
	else
		message.msg_window = vim.api.nvim_open_win(message.history_buffer, true, window_config);
	end

	vim.wo[message.history_window].wrap = true;
	vim.wo[message.history_window].linebreak = true;

	vim.api.nvim__redraw({ flush = true, win = message.history_window });
end

------------------------------------------------------------------------------

message.msg_show = function (kind, content, replace_last)
	if replace_last then
	else
		if kind == "confirm" then
			local _, e = pcall(message.__confirm, {
				kind = kind,
				content = content,
			});

			table.insert(log.entries, e)
		elseif kind == "search_count" then
			--- Do not handle search count as messages.
			return;
		elseif kind == "return_prompt" then
			--- Hit `<ESC>` on hit-enter prompts.
			--- or else we get stuck.
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<ESC>", true, false, true), "n", false);
			return;
		else
			local current_id = message.id;
			local lines = utils.to_lines(content);

			local processor = spec.get_msg_processor(kind, content, lines) or {};
			local duration = processor.duration or 600;

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

			message.last = message.id;
			message.id = message.id + 1;

			vim.schedule(function ()
				local _, e = pcall(message.__render);
				table.insert(log.entries, e)
			end)

			-- message.__append({
			-- 	kind = kind,
			-- 	content = content,
			-- }, 5000);
		end
	end
end

message.msg_history_show = function (entries)
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "n", false);

	vim.schedule(function ()
		local _, e = pcall(message.__history, entries);
		table.insert(log.entries, e)
	end)
end

-- message.msg_showmode = function (content)
-- 	table.insert(log.entries, vim.inspect(content))
-- end

message.msg_showcmd = function (content)
	table.insert(log.entries, vim.inspect(content))
end

------------------------------------------------------------------------------

--- Handles message events.
---@param event string
---@param ... any
message.handle = function (event, ...)
	local _, _ = pcall(message[event], ...);

	vim.api.nvim__redraw({
		flush = true,
		win = message.msg_window
	});
end

message.setup = function ()
	message.__prepare();

	vim.api.nvim_create_autocmd("VimResized", {
		callback = function ()
			if vim.g.__confirm_msg then
				--- If a confirmation window is active,
				--- redraw it.
				message.__confirm(vim.g.__confirm_msg);
			end

			message.__render();
		end
	});
end

return message;

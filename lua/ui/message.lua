--- Custom message for
--- Neovim.
local message = {};

local log = require("ui.log");
local utils = require("ui.utils");

------------------------------------------------------------------------------

---@type integer
message.namespace = vim.api.nvim_create_namespace("ui.message")

---@type integer, integer Buffer & window for messages.
message.msg_buffer, message.msg_window = nil, nil;

---@type integer, integer Buffer & window for showing stuff.
message.show_buffer, message.show_window = nil, nil;

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
	if not message.msg_buffer or vim.api.nvim_buf_is_valid(message.msg_buffer) == false then
		message.msg_buffer = vim.api.nvim_create_buf(false, true);
	end

	if not message.show_buffer or vim.api.nvim_buf_is_valid(message.show_buffer) == false then
		message.show_buffer = vim.api.nvim_create_buf(false, true);
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

message.__append = function (obj, duration)
	local current_id = message.id;
	table.insert(log.entries, "Added " .. (vim.uv.hrtime() / 1e6))

	message.history[message.id] = obj;
	message.visible[message.id] = vim.tbl_extend("force", obj, {
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
end

message.__remove = function (id)
	table.insert(log.entries, "Removed " .. (vim.uv.hrtime() / 1e6))
	if message.visible[id] then
		message.visible[id] = nil;

		vim.schedule(function ()
			local _, e = pcall(message.__render);
			table.insert(log.entries, e)
		end)
	end
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

		lines = vim.list_extend(lines, m_lines)
		exts = vim.list_extend(exts, m_exts)
	end

	vim.api.nvim_buf_clear_namespace(message.msg_buffer, message.namespace, 0, -1);
	vim.api.nvim_buf_set_lines(message.msg_buffer, 0, -1, false, lines);

	local window_config = {
		relative = "editor",

		row = 0,
		col = 0,

		width = 40,
		height = 5,

		border = "rounded",
		style = "minimal",

		hide = false
	}

	if message.msg_window and vim.api.nvim_win_is_valid(message.msg_window) then
		vim.api.nvim_win_set_config(message.msg_window, window_config);
	else
		message.msg_window = vim.api.nvim_open_win(message.msg_buffer, false, window_config);
	end
end

------------------------------------------------------------------------------

message.msg_show = function (kind, content, replace_last)
	if replace_last then
	else
		message.__append({
			kind = kind,
			content = content,
		}, 5000);
	end
end

------------------------------------------------------------------------------

--- Handles message events.
---@param event string
---@param ... any
message.handle = function (event, ...)
	local _, _ = pcall(message[event], ...);

	vim.api.nvim__redraw({
		flush = true
	});
end

message.setup = function ()
	message.__prepare();
end

return message;

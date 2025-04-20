local popup = {};

local spec = require("ui.spec");
local log = require("ui.log");
local utils = require("ui.utils");

------------------------------------------------------------------------------

popup.state = {};

------------------------------------------------------------------------------

---@type integer Namespace for the decorations in the command-line.
popup.namespace = vim.api.nvim_create_namespace("ui.popup");

---@type integer, integer[] Cmdline buffer & window.
popup.buffer, popup.window = nil, {};

------------------------------------------------------------------------------

--- Preparation steps before opening the command-line.
popup.__prepare = function ()
	---|fS

	--- Create command-line buffer.
	if not popup.buffer or vim.api.nvim_buf_is_valid(popup.buffer) == false then
		popup.buffer = vim.api.nvim_create_buf(false, true);
	end

	---@type integer
	local tab = vim.api.nvim_get_current_tabpage();

	-- Open a hidden window.
	-- We can't open new windows while processing
	-- UI events.
	-- But, we can change an already open window's
	-- configuration. That's why we open a hidden
	-- window first.
	if not popup.window[tab] or vim.api.nvim_win_is_valid(popup.window[tab]) == false then
		popup.window[tab] = vim.api.nvim_open_win(popup.buffer, false, {
			relative = "editor",

			row = 0,
			col = 0,

			width = 1,
			height = 1,

			hide = true,
			focusable = false
		});

		vim.api.nvim_win_set_var(popup.window[tab], "ui_window", true);
		vim.wo[popup.window[tab]].sidescrolloff = math.floor(vim.o.columns * 0.5) or 36;
	end

	---|fE
end

popup.__hide = function ()
	---|fS

	local tab = vim.api.nvim_get_current_tabpage();
	local win_config = {
		relative = "editor",

		row = 0,
		col = 0,

		width = 1,
		height = 1,

		style = "minimal",

		hide = true,
		focusable = false
	};

	pcall(vim.api.nvim_win_set_config, popup.window[tab], win_config);

	---|fE
end

popup.__render = function ()
	---|fS

	if #popup.state.items == 0 then
		return;
	end

	popup.__prepare();

	local sepaarator = spec.config.popupmenu.sepaarator or " ";

	local line = "";
	local hls = {};

	local X = 0;

	for i, item in ipairs(popup.state.items) do
		local item_config = spec.get_item_config(item[1], item[2], item[3], item[4]) or {};
		local text = table.concat({
			item_config.padding_left or "",
			item_config.icon or "",
			item_config.text or item[1] or "",
			item_config.padding_right or "",
		});

		if (i - 1) == popup.state.selected then
			table.insert(hls, { #line, #(line .. text), item_config.select_hl or "CursorLine" });
			X = #line + math.floor(#text / 2);
		elseif item_config.normal_hl then
			table.insert(hls, { #line, #(line .. text), item_config.item_hl });
		end

		if item_config.icon_hl then
			table.insert(hls, {
				#(line .. (item_config.padding_left or "")),
				#(line .. (item_config.padding_left or "") .. (item_config.icon or "")),
				item_config.icon_hl
			});
		end

		line = line .. text;

		if i ~= #popup.state.items then
			line = line .. sepaarator;
		end
	end

	vim.api.nvim_buf_clear_namespace(popup.buffer, popup.namespace, 0, -1);
	vim.api.nvim_buf_set_lines(popup.buffer, 0, -1, false, { line });

	for _, hl in ipairs(hls) do
		log.assert(
			pcall(
				vim.api.nvim_buf_set_extmark,

				popup.buffer,
				popup.namespace,

				0,
				hl[1],

				{
					end_col = hl[2],
					hl_group = hl[3]
				}
			)
		);
	end

	local tooltip = utils.eval(spec.config.popupmenu.tooltip, popup.state);

	if tooltip then
		pcall(
			vim.api.nvim_buf_set_extmark,

			popup.buffer,
			popup.namespace,

			0,
			0,

			{
				virt_text_pos = "right_align",
				virt_text = tooltip
			}
		);
	end

	local tab = vim.api.nvim_get_current_tabpage();
	local win_config = {
		relative = "editor",

		row = vim.o.lines - 1,
		col = 0,

		width = vim.o.columns,
		height = 1,

		style = "minimal",
		hide = false,
		focusable = false
	};

	pcall(vim.api.nvim_win_set_config, popup.window[tab], win_config);
	pcall(vim.api.nvim_win_set_cursor, popup.window[tab], { 1, X });

	vim.api.nvim__redraw({
		flush = true,
		win = popup.window[tab]
	});

	---|fE
end

------------------------------------------------------------------------------

popup.popupmenu_show = function (items, selected, row, col, grid)
	popup.state = vim.tbl_extend("force", popup.state, {
		items = items,

		selected = selected,
		row = row,
		col = col,

		grid = grid
	});

	popup.__render();
end

popup.popupmenu_select = function (selected)
	popup.state = vim.tbl_extend("force", popup.state, {
		selected = selected,
	});

	popup.__render();
end

popup.popupmenu_hide = function ()
	popup.state = vim.tbl_extend("force", popup.state, {
		items = {}
	});

	popup.__hide();
end

------------------------------------------------------------------------------

--- Handles command-line events.
---@param event string
---@param ... any
popup.handle = function (event, ...)
	log.assert(
		pcall(popup[event], ...)
	);
end

--- Sets up the popup module.
popup.setup = function ()
	vim.api.nvim_create_autocmd("TabEnter", {
		callback = function ()
			popup.__prepare();
		end
	});

	popup.__prepare();
end

return popup;

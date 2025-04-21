local popup = {};

local spec = require("ui.spec");
local log = require("ui.log");
local utils = require("ui.utils");

------------------------------------------------------------------------------

---@type ui.popupmenu.state
popup.state = {
	items = {},
	selected = -1,

	row = 0,
	col = 0,

	grid = -1,
};

------------------------------------------------------------------------------

---@type integer Namespace for the decorations in the command-line.
popup.namespace = vim.api.nvim_create_namespace("ui.popup");

---@type integer, integer[] Popup buffer & window.
popup.buffer, popup.window = nil, {};

---@type integer, integer[] Information buffer & window.
popup.info_buffer, popup.info_window = nil, {}

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

		vim.wo[popup.window[tab]].wrap = false;
		vim.wo[popup.window[tab]].sidescrolloff = math.floor(vim.o.columns * 0.5) or 36;
	end

	--- Create command-line buffer.
	if not popup.info_buffer or vim.api.nvim_buf_is_valid(popup.info_buffer) == false then
		popup.info_buffer = vim.api.nvim_create_buf(false, true);
	end

	-- Open a hidden window.
	-- We can't open new windows while processing
	-- UI events.
	-- But, we can change an already open window's
	-- configuration. That's why we open a hidden
	-- window first.
	if not popup.info_window[tab] or vim.api.nvim_win_is_valid(popup.info_window[tab]) == false then
		popup.info_window[tab] = vim.api.nvim_open_win(popup.info_buffer, false, {
			relative = "editor",

			row = 0,
			col = 0,

			width = 1,
			height = 1,

			hide = true,
			focusable = false
		});

		vim.api.nvim_win_set_var(popup.info_window[tab], "ui_window", true);

		vim.wo[popup.info_window[tab]].wrap = true;
		vim.wo[popup.info_window[tab]].linebreak = true;
	end

	---|fE
end

--- Hides completion & information window.
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
	pcall(vim.api.nvim_win_set_config, popup.info_window[tab], win_config);

	---|fE
end

--- Shows additional information in a window.
---@param item ui.popupmenu.item
popup.__info = function (item)
	---|fS

	if not item or item[4] == "" then
		return;
	end

	local lines = vim.split(item[4], "\n", { trimempty = true });
	vim.api.nvim_buf_set_lines(popup.info_buffer, 0, -1, false, lines);

	local W = math.min(utils.max_len(lines), math.floor(vim.o.columns * 0.4));
	local H = utils.wrapped_height(lines, W);

	local tab = vim.api.nvim_get_current_tabpage();
	local win_config = {
		relative = "editor",

		row = vim.o.lines - (1 + H),
		col = 0,

		width = W,
		height = H,

		style = "minimal",
		hide = false,
		focusable = false
	};

	pcall(vim.api.nvim_win_set_config, popup.info_window[tab], win_config);

	vim.api.nvim__redraw({
		flush = true,
		win = popup.info_window[tab]
	});

	---|fE
end

--- Renders menu as a strip.
popup.__strip_renderer = function ()
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

			popup.__info(item);
		elseif item_config.normal_hl then
			table.insert(hls, { #line, #(line .. text), item_config.normal_hl });
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

--- Renders menu as a completion menu.
popup.__completion_renderer = function ()
	---|fS

	if #popup.state.items == 0 then
		return;
	end

	popup.__prepare();
	local W = 0;

	for i, item in ipairs(popup.state.items) do
		local item_config = spec.get_item_config(item[1], item[2], item[3], item[4]) or {};
		local text = table.concat({
			item_config.padding_left or "",
			item_config.icon or "",
			item_config.text or item[1] or "",
			item_config.padding_right or "",
		});

		W = math.max(W, vim.fn.strdisplaywidth(text));

		if i == 1 then
			vim.api.nvim_buf_set_lines(popup.buffer, 0, -1, false, { text });
		else
			vim.api.nvim_buf_set_lines(popup.buffer, -1, -1, false, { text });
		end

		if (i - 1) == popup.state.selected then
			pcall(vim.api.nvim_buf_set_extmark, popup.buffer, popup.namespace, i - 1, 0, {
				end_col = #text,
				line_hl_group = item_config.select_hl or "CursorLine"
			});

			popup.__info(item);
		elseif item_config.normal_hl then
			pcall(vim.api.nvim_buf_set_extmark, popup.buffer, popup.namespace, i - 1, 0, {
				end_col = #text,
				line_hl_group = item_config.normal_hl
			});
		end

		if item_config.icon_hl then
			pcall(vim.api.nvim_buf_set_extmark, popup.buffer, popup.namespace, i - 1, #(item_config.padding_left or ""), {
				end_col = #(item_config.padding_left or "") + #(item_config.icon or ""),
				hl_group = item_config.icon_hl
			});
		end
	end

	local tooltip = utils.eval(spec.config.popupmenu.tooltip, popup.state);

	local win = vim.api.nvim_get_current_win();
	local pos = vim.api.nvim_win_get_cursor(win);

	local H = #popup.state.items;
	local screenpos = vim.fn.screenpos(win, pos[1], pos[2]);

	log.print(vim.inspect(screenpos))

	local tab = vim.api.nvim_get_current_tabpage();
	local win_config = {
		relative = "cursor",

		row = 0,
		col = 0,

		width = W,
		height = H,

		footer = tooltip,
		footer_pos = tooltip and "right" or nil,

		style = "minimal",
		hide = false,
		focusable = false
	};

	if screenpos.row + H >= vim.o.lines then
		win_config.row = 0;

		if screenpos.curscol + W >= vim.o.columns then
			win_config.anchor = "SE";
			win_config.col = 2;
		else
			win_config.anchor = "SW";
			win_config.col = 1;
		end
	else
		win_config.row = 1;

		if screenpos.curscol + W >= vim.o.columns then
			win_config.anchor = "NE";
			win_config.col = 2;
		else
			win_config.anchor = "NW";
			win_config.col = 1;
		end
	end

	pcall(vim.api.nvim_win_set_config, popup.window[tab], win_config);
	pcall(vim.api.nvim_win_set_cursor, popup.window[tab], { popup.state.selected + 1, 0 });

	vim.api.nvim__redraw({
		flush = true,
		win = popup.window[tab]
	});

	---|fE
end

--- Renders popup menu.
popup.__render = function ()
	---|fS

	local mode = vim.api.nvim_get_mode().mode;

	if mode == "c" then
		popup.__strip_renderer();
	else
		popup.__completion_renderer();
	end

	if package.loaded["ui.cmdline"] then
		pcall(package.loaded["ui.cmdline"].__render)
	end

	---|fE
end

------------------------------------------------------------------------------

---@param items ui.popupmenu.item[]
---@param selected integer | -1
---@param row integer
---@param col integer
---@param grid integer | -1
popup.popupmenu_show = function (items, selected, row, col, grid)
	---|fS

	popup.state = vim.tbl_extend("force", popup.state, {
		items = items,

		selected = selected,
		row = row,
		col = col,

		grid = grid
	});

	popup.__render();

	---|fE
end

---@param selected integer | -1
popup.popupmenu_select = function (selected)
	---|fS

	popup.state = vim.tbl_extend("force", popup.state, {
		selected = selected,
	});

	popup.__render();

	---|fE
end

popup.popupmenu_hide = function ()
	---|fS

	popup.state = vim.tbl_extend("force", popup.state, {
		items = {}
	});

	popup.__hide();

	---|fE
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

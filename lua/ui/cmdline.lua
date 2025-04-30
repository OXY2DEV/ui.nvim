--- Custom command-line for
--- Neovim.
local cmdline = {};

local spec = require("ui.spec");
local log = require("ui.log");
local utils = require("ui.utils");

------------------------------------------------------------------------------

---@type integer Namespace for the decorations in the command-line.
cmdline.namespace = vim.api.nvim_create_namespace("ui.cmdline");

---@type integer Namespace for the cursor in command-line.
cmdline.cursor_ns = vim.api.nvim_create_namespace("ui.cmdline.cursor");

---@type integer, integer[] Cmdline buffer & window.
cmdline.buffer, cmdline.window = nil, {};

------------------------------------------------------------------------------

---@type ui.cmdline.style__static
cmdline.style = nil;

---@type ui.cmdline.state
cmdline.state = {
	pos = 0,
	firstc = ":",
	indent = 0,
	level = 1,
	prompt = nil,

	c = "",
	shift = false
};

cmdline.old_state = {
	pos = 0,
	firstc = ":",
	indent = 0,
	level = 1,
	prompt = nil,

	c = "",
	shift = false
};

--- Gets cmdline state.
---@param key string
---@param fallback any
---@return any
cmdline.get_state = function (key, fallback)
	return cmdline.state[key] or fallback;
end

--- Updates cmdline state.
---@param state table<string, any>
cmdline.set_state = function (state)
	cmdline.state = vim.tbl_extend("force", cmdline.state, state);
end

------------------------------------------------------------------------------

--- Preparation steps before opening the command-line.
cmdline.__prepare = function ()
	---|fS

	--- Create command-line buffer.
	if not cmdline.buffer or vim.api.nvim_buf_is_valid(cmdline.buffer) == false then
		cmdline.buffer = vim.api.nvim_create_buf(false, true);
	end

	---@type integer
	local tab = vim.api.nvim_get_current_tabpage();

	-- Open a hidden window.
	-- We can't open new windows while processing
	-- UI events.
	-- But, we can change an already open window's
	-- configuration. That's why we open a hidden
	-- window first.
	if not cmdline.window[tab] or not vim.api.nvim_win_is_valid(cmdline.window[tab]) then
		cmdline.window[tab] = vim.api.nvim_open_win(cmdline.buffer, false, {
			relative = "editor",

			row = 0,
			col = 0,

			width = 1,
			height = 1,

			border = "none",

			hide = true,
			focusable = false
		});

		vim.api.nvim_win_set_var(cmdline.window[tab], "ui_window", true);
	end

	---|fE
end

--- Creates the lines & decorations for the command-line.
---@return ui.cmdline.lines
---@return ui.cmdline.decorations
---@return ui.cmdline.line_stat
cmdline.__lines = function ()
	---|fS

	cmdline.decorations = {};

	-- Process the lines of the command-line.
	local current_lines, current_exts = utils.process_content(
		cmdline.get_state("content", {})
	);

	-- NOTE, Remove decorations from the command-line text.
	-- We will use syntax highlighting instead.
	--
	-- This behavior may change in the future.
	for e, _ in ipairs(current_exts) do
		current_exts[e] = {};
	end

	---@type ui.cmdline.style__static
	cmdline.style = spec.get_cmdline_style(cmdline.state, current_lines);

	local icon_w = utils.virt_len(cmdline.style.icon);

	for l, line in ipairs(current_lines) do
		current_lines[l] = string.rep(" ", icon_w) .. line .. " ";
	end

	---@type ui.cmdline.lines, ui.cmdline.decorations
	local context_lines, context_exts = {}, {};
	local context = cmdline.get_state("lines", {});

	--- Process each line of available context.
	--- This mostly used for the block mode.
	for _, line in ipairs(context) do
		local tmp_lines, tmp_exts = utils.process_content(line);

		context_lines = vim.list_extend(context_lines, tmp_lines);
		context_exts = vim.list_extend(context_exts, tmp_exts);
	end

	---@type ui.cmdline.lines, ui.cmdline.decorations
	local title_lines, title_exts = {}, {};

	--- If title exists then process it.
	if cmdline.style and cmdline.style.title then
		title_lines, title_exts = utils.process_virt(cmdline.style.title);
	end

	--- Output structure should be,
	---                 / Title
	---  command-line --  Context
	---                 \ Command-line
	---@type ui.cmdline.lines, ui.cmdline.decorations
	local output_lines, output_exts = vim.deepcopy(title_lines), vim.deepcopy(title_exts);

	output_lines = vim.list_extend(output_lines, context_lines);
	output_exts = vim.list_extend(output_exts, context_exts);

	output_lines = vim.list_extend(output_lines, current_lines);
	output_exts = vim.list_extend(output_exts, current_exts);

	return output_lines, output_exts, {
		context_size = #context_lines,
		cmdline_size = #current_lines
	};

	---|fE
end

--- Sets the cursor.
---@param lines string[]
cmdline.__cursor = function (lines)
	---|fS

	---@type integer Byte position of the cursor.
	local pos = cmdline.get_state("pos", 0);
	local line = lines[#lines] or "";

	local icon_w = utils.virt_len(cmdline.style.icon);
	pos = icon_w + pos;

	---@type integer
	local tab = vim.api.nvim_get_current_tabpage();

	log.assert(
		"ui/cmdline.lua → nvim_win_set_cursor",
		pcall(
			vim.api.nvim_win_set_cursor,

			cmdline.window[tab],
			{
				vim.api.nvim_buf_line_count(cmdline.buffer), -- This is 1-indexed.
				pos
			}
		)
	);

	-- Clear previous cursor.
	vim.api.nvim_buf_clear_namespace(cmdline.buffer, cmdline.cursor_ns, 0, -1);
	local offset_len = 0;

	if cmdline.style.offset and (pos - icon_w) >= cmdline.style.offset then
		offset_len = #vim.fn.strcharpart(line, 0, cmdline.style.offset);

		-- If `offset` exists and the cursor position is >= to the offset
		-- we hide the leading part of the command-line(till `offset` characters).
		log.assert(
			"ui/cmdline.lua → text_conceal",
			pcall(
				vim.api.nvim_buf_set_text,

				cmdline.buffer,

				#lines - 1, icon_w,
				#lines - 1, icon_w + offset_len,

				{
					""
				}
			)
		);
	end

	---|fE
end

--- Draws special characters under cursor.
--- BUG, this is a separate function from
--- `__cursor` as changing text breaks it.
cmdline.__special = function ()
	---|fS

	---@type integer Byte position of the cursor.
	local pos = cmdline.get_state("pos", 0);
	local lines = vim.api.nvim_buf_get_lines(cmdline.buffer, 0, -1, false);
	local line = lines[#lines] or "";

	local icon_w = utils.virt_len(cmdline.style.icon);
	pos = icon_w + pos;

	-- Clear previous cursor.
	vim.api.nvim_buf_clear_namespace(cmdline.buffer, cmdline.cursor_ns, 0, -1);
	local offset_len = 0;

	if cmdline.style.offset and (pos - icon_w) >= cmdline.style.offset then
		offset_len = #vim.fn.strcharpart(line, 0, cmdline.style.offset);
	end

	pos = pos - offset_len;

	---@type integer Byte size of the character under the cursor.
	local to = #vim.fn.strcharpart(string.sub(line, pos, #line), 0, 1);

	local char = cmdline.get_state("c", "");
	local shift = cmdline.get_state("shift", false);

	if char ~= "" then
		log.assert(
			"ui/cmdline.lua → fake_cursor_char",
			pcall(
				vim.api.nvim_buf_set_extmark,

				cmdline.buffer,
				cmdline.cursor_ns,

				#lines - 1,
				pos,

				{
					end_col = math.min(pos + to, #line),
					virt_text_pos = shift == true and "inline" or "overlay",

					virt_text = {
						{ char, cmdline.style.cursor or "Cursor" }
					}
				}
			)
		);

		cmdline.set_state({
			c = ""
		});
	end

	---|fE
end

--- Renders the command-line.
cmdline.__render = function ()
	---|fS

	log.assert(
		"ui/cmdline.lua → __prepare",
		pcall(cmdline.__prepare)
	);

	local lines, extmarks, _ = cmdline.__lines();

	local H = #lines;
	vim.g.__ui_cmd_height = H;

	local win_config = {
		---|fS

		relative = "editor",
		style = "minimal",
		zindex = 300,

		row = vim.o.lines - (vim.o.cmdheight + H + 1),
		col = 0,

		border = "none",

		width = vim.o.columns,
		height = H,

		hide = false,
		focusable = false

		---|fE
	};

	local function render_callback ()
		---|fS

		-- Clear the buffer of old decorations.
		vim.api.nvim_buf_clear_namespace(cmdline.buffer, cmdline.namespace, 0, -1);

		-- Set new content(with filetype).
		vim.bo[cmdline.buffer].ft = cmdline.style.filetype or "vim";
		vim.api.nvim_buf_set_lines(cmdline.buffer, 0, -1, false, lines);

		-- Add all the highlight groups.
		for l, line in ipairs(extmarks) do
			---|fS

			for _, ext in ipairs(line) do
				if ext == "" then
					goto continue;
				end

				vim.api.nvim_buf_set_extmark(cmdline.buffer, cmdline.namespace, l - 1, ext[1], {
					end_col = ext[2],
					hl_group = ext[3]
				});

			    ::continue::
			end

			---|fE
		end

		---@type integer
		local tab = vim.api.nvim_get_current_tabpage();

		vim.api.nvim_buf_set_extmark(cmdline.buffer, cmdline.namespace, #lines - 1, 0, {
			virt_text_pos = "overlay",
			virt_text = cmdline.style.icon
		})

		log.assert(
			"ui/cmdline.lua → window",
			pcall(vim.api.nvim_win_set_config, cmdline.window[tab], win_config)
		);

		local winhl = cmdline.style.winhl or "";

		-- Disable search highlighting.
		if type(winhl) ~= "string" then
			winhl = "Search:None,CurSearch:None";
		elseif winhl == "" then
			winhl = "Search:None,CurSearch:None";
		else
			winhl = winhl .. ",Search:None,CurSearch:None";
		end

		vim.wo[cmdline.window[tab]].winhl = winhl;

		vim.wo[cmdline.window[tab]].sidescrolloff = math.floor(vim.o.columns * 0.5) or 36;
		vim.wo[cmdline.window[tab]].scrolloff = 0;

		vim.wo[cmdline.window[tab]].conceallevel = 3;
		vim.wo[cmdline.window[tab]].concealcursor = "nvic";

		cmdline.__cursor(lines);

		if package.loaded["ui.message"] then
			log.assert(
				"ui/cmdline.lua → message_refresh",
				pcall(package.loaded["ui.message"].__render)
			);

			log.assert(
				"ui/cmdline.lua → showcmd_refresh",
				pcall(package.loaded["ui.message"].__showcmd)
			);
		end

		vim.api.nvim__redraw({
			flush = true,
			cursor = true,

			win = cmdline.window[tab]
		});

		---|fE
	end

	if vim.list_contains({ "/", "?" }, cmdline.state.firstc) or string.match(lines[#lines], "^%s*[%S]*s/") then
		-- When we do `:s/`(aka substitute) Neovim will
		-- schedule the screen updates *after* the preview.
		--
		-- So, we update the screen immediately.
		-- Same when searching.
		render_callback();
	else
		vim.schedule(render_callback);
	end

	---|fE
end

------------------------------------------------------------------------------

---@param content ui.cmdline.content
---@param pos integer
---@param firstc ":" | "?" | "/" | "="
---@param prompt string
---@param indent integer
---@param level integer
cmdline.cmdline_show = function (content, pos, firstc, prompt, indent, level, hl_id)
	---|fS

	cmdline.set_state({
		content = content,
		pos = pos,
		firstc = firstc,
		prompt = prompt,
		indent = indent,
		level = level,
		hl_id = hl_id,
	});

	if vim.deep_equal(cmdline.old_state, cmdline.state) then
		return;
	else
		cmdline.old_state = vim.deepcopy(cmdline.state);
	end

	-- This is used to communicate between
	-- the cmdline & message module when
	-- confirmation prompts are shown.
	utils.confirm_keys(prompt, content);
	cmdline.__render();

	---|fE
end

---@param pos integer
---@param level integer
cmdline.cmdline_pos = function (pos, level)
	---|fS

	cmdline.set_state({
		pos = pos,
		level = level
	});

	cmdline.__render();

	---|fE
end

cmdline.cmdline_special_char = function (c, shift, level)
	---|fS

	cmdline.set_state({
		c = c,
		shift = shift,
		level = level
	});

	---@type integer
	local tab = vim.api.nvim_get_current_tabpage();

	-- Special characters should be rendered
	-- immediately.
	cmdline.__special();
	vim.api.nvim__redraw({ flush = true, cursor = true, win = cmdline.window[tab] })

	---|fE
end

--- Exited cmdline.
cmdline.cmdline_hide = function ()
	---|fS

	utils.confirm_keys();

	-- Reset exported height.
	vim.g.__ui_cmd_height = 0;

	vim.schedule(function ()
		-- We can't open/close windows.
		-- But, we can hide them here.
		for _, win in pairs(cmdline.window) do
			log.assert(
				"ui/cmdline.lua",
				pcall(vim.api.nvim_win_set_config, win, { hide = true })
			);
		end

		--- Re-render messages to update the window
		--- position.
		if package.loaded["ui.message"] then
			log.assert(
				"ui/cmdline.lua",
				pcall(package.loaded["ui.message"].__render)
			);
		end

		-- Sometimes the statusline doesn't update after
		-- mode change. So, we force it here.
		vim.api.nvim__redraw({
			flush = true,
			cursor = true,
			statusline = true
		});
	end);

	---|fE
end

---@param lines ui.cmdline.content
cmdline.cmdline_block_show = function (lines)
	---|fS

	cmdline.set_state({
		lines = lines,
	});

	cmdline.__render();

	---|fE
end

---@param line [ integer, string ][]
cmdline.cmdline_block_append = function (line)
	---|fS

	local old = cmdline.get_state("lines", {});
	table.insert(old, line);

	cmdline.set_state({
		lines = old,
	});

	cmdline.__render();

	---|fE
end

cmdline.cmdline_block_hide = function ()
	---|fS

	cmdline.set_state({
		lines = {},
	});
	cmdline.state.lines = nil;

	cmdline.cmdline_hide();

	---|fE
end

------------------------------------------------------------------------------

--- Handles command-line events.
---@param event string
---@param ... any
cmdline.handle = function (event, ...)
	---|fS

	log.level_inc();

	log.assert(
		"ui/cmdline.lua",
		pcall(cmdline[event], ...)
	);

	log.level_dec();
	log.print(vim.inspect(cmdline.state), "ui/cmdline.lua", "debug");

	---|fE
end

--- Sets up the cmdline module.
cmdline.setup = function ()
	---|fS

	vim.api.nvim_create_autocmd("TabEnter", {
		callback = function ()
			log.assert(
				"ui/cmdline.lua",
				pcall(cmdline.__prepare)
			);
		end
	});

	log.assert(
		"ui/cmdline.lua",
		pcall(cmdline.__prepare)
	);

	---|fE
end

return cmdline;

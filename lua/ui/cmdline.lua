--- Custom command-line for
--- Neovim.
local cmdline = {};

local spec = require("ui.spec");
local log = require("ui.log");
local utils = require("ui.utils");

------------------------------------------------------------------------------

cmdline.config = nil;
cmdline.state = {};

cmdline.get_state = function (key, fallback)
	return cmdline.state[key] or fallback;
end

cmdline.set_state = function (state)
	cmdline.state = vim.tbl_extend("force", cmdline.state, state);
end

------------------------------------------------------------------------------

---@type integer Command-line namespace.
cmdline.namespace = vim.api.nvim_create_namespace("ui.cmdline");

---@type integer Namespace for the cursor in command-line.
cmdline.cursor_ns = vim.api.nvim_create_namespace("ui.cmdline.cursor");

--- Cmdline buffer & window.
---@type integer, integer
cmdline.buffer, cmdline.window = nil, nil;

------------------------------------------------------------------------------

cmdline.__prepare = function ()
	--- Temporarily disable 'cursorline'.
	if not vim.g.__ui_cursorline then
		vim.g.__ui_cursorline = vim.o.cursorline == true;
		vim.o.cursorline = false;
	end

	--- Create command-line buffer.
	if not cmdline.buffer or vim.api.nvim_buf_is_valid(cmdline.buffer) == false then
		cmdline.buffer = vim.api.nvim_create_buf(false, true);
	end
end

cmdline.__lines = function ()
	local current_lines, current_exts = utils.process_content(
		cmdline.get_state("content", {})
	);

	--- Remove decorations from the command-line text.
	--- We will use syntax highlighting instead.
	for e, _ in ipairs(current_exts) do
		current_exts[e] = {};
	end

	--- Add an extra for the *fake* cursor.
	for l, line in ipairs(current_lines) do
		current_lines[l] = line .. " ";
	end

	--- Update config.
	cmdline.config = spec.get_cmdline_config(cmdline.state, current_lines);

	local context_lines, context_exts = {}, {};
	local context = cmdline.get_state("lines", {});

	--- Process each line of context.
	for _, line in ipairs(context) do
		local tmp_lines, tmp_exts = utils.process_content(line);

		context_lines = vim.list_extend(context_lines, tmp_lines);
		context_exts = vim.list_extend(context_exts, tmp_exts);
	end

	local title_lines, title_exts = {}, {};

	--- If title exists then process it.
	if cmdline.config and cmdline.config.title then
		title_lines, title_exts = utils.process_virt(cmdline.config.title);
	end

	--- Output structure should be,
	--- * Title
	--- * Context
	--- * Command-line
	local output_lines, output_exts = vim.deepcopy(title_lines), vim.deepcopy(title_exts);

	output_lines = vim.list_extend(output_lines, context_lines);
	output_exts = vim.list_extend(output_exts, context_exts);

	output_lines = vim.list_extend(output_lines, current_lines);
	output_exts = vim.list_extend(output_exts, current_exts);

	return output_lines, output_exts, { #title_lines, #context_lines, #current_lines };
end

--- Sets the cursor.
cmdline.__cursor = function ()
	---|fS

	local lines, _ = cmdline.__lines();

	if #lines == 0 then
		table.insert(lines, "");
	end

	for l, line in ipairs(lines) do
		lines[l] = line .. " ";
	end

	local pos = cmdline.get_state("pos", 0);
	local line = lines[#lines] or "";

	---@type integer
	local to = #vim.fn.strcharpart(string.sub(line, pos, #line), 0, 1);

	vim.api.nvim_win_set_cursor(cmdline.window, {
		vim.api.nvim_buf_line_count(cmdline.buffer),
		pos
	})

	vim.api.nvim_buf_clear_namespace(cmdline.buffer, cmdline.cursor_ns, 0, -1);
	vim.api.nvim_buf_set_extmark(cmdline.buffer, cmdline.cursor_ns, #lines - 1, pos, {
		end_col = pos + to,
		hl_group = "@comment.todo"
	});

	---|fE
end

cmdline.__render = function ()
	cmdline.__prepare();

	local lines, extmarks, stat = cmdline.__lines();
	local H = #lines;

	---|fS

	local win_config = {
		relative = "editor",
		style = "minimal",
		zindex = 300,

		row = vim.o.lines - (cmdline.__statualine_visible and 1 or 1) - (vim.o.cmdheight + H),
		col = 0,

		width = vim.o.columns,
		height = H,

		hide = false
	};

	vim.schedule(function ()
		--- Clear the buffer of old decorations.
		vim.api.nvim_buf_clear_namespace(cmdline.buffer, cmdline.namespace, 0, -1);

		--- Set new content(with filetype).
		vim.api.nvim_buf_set_lines(cmdline.buffer, 0, -1, false, lines);
		vim.bo[cmdline.buffer].ft = cmdline.config.filetype or "vim";

		for l, line in ipairs(extmarks) do
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
		end

		if cmdline.config.icon then
			for l, _ in ipairs(lines) do
				if l == #lines then
					vim.api.nvim_buf_set_extmark(cmdline.buffer, cmdline.namespace, l - 1, 0, {
						virt_text_pos = "inline",
						virt_text = cmdline.config.icon
					});
				elseif l > stat[1] then
					local size = utils.virt_len(cmdline.config.icon);

					vim.api.nvim_buf_set_extmark(cmdline.buffer, cmdline.namespace, l - 1, 0, {
						virt_text_pos = "inline",
						virt_text = {
							{ string.rep(" ", size) },
						}
					});
				end
			end
		end

		if not cmdline.window or vim.api.nvim_win_is_valid(cmdline.window) == false then
			cmdline.window = vim.api.nvim_open_win(cmdline.buffer, false, win_config);
			vim.wo[cmdline.window].sidescrolloff = math.floor(vim.o.columns * 0.5) or 36;
		else
			local _, e = pcall(vim.api.nvim_win_set_config, cmdline.window, win_config);
			-- if e then vim.print(e); end
		end

		cmdline.__cursor()
		vim.wo[cmdline.window].winhl = cmdline.config.winhl or "";

		vim.api.nvim__redraw({ flush = true, win = cmdline.window })
	end);

	---|fE
end

------------------------------------------------------------------------------

--- Cmdline draw.
---@param content [ string[], string ][]
---@param pos integer
---@param firstc string
---@param prompt string
---@param indent integer
---@param level integer
cmdline.cmdline_show = function (content, pos, firstc, prompt, indent, level, hl_id)
	cmdline.set_state({
		content = content,
		pos = pos,
		firstc = firstc,
		prompt = prompt,
		indent = indent,
		level = level,
		hl_id = hl_id,
	});

	cmdline.__render();
end

--- Cmdline cursor position change.
---@param pos any
---@param level any
cmdline.cmdline_pos = function (pos, level)
	cmdline.set_state({
		pos = pos,
		level = level
	});

	vim.schedule(function ()
		cmdline.__cursor();
		vim.api.nvim__redraw({ flush = true, win = cmdline.window })
	end)
end

--- Exited cmdline.
cmdline.cmdline_hide = function ()
	vim.schedule(function ()
		--- We can't open/close windows.
		--- But, we can hide them here.
		pcall(vim.api.nvim_win_set_config, cmdline.window, { hide = true });

		if vim.g.__ui_cursorline ~= nil then
			vim.o.cursorline = vim.g.__ui_cursorline;
			vim.g.__ui_cursorline = nil;
		end

		vim.api.nvim__redraw({
			flush = true,
			statusline = true
		});
	end)
end

--- Cmdline block event.
---@param lines any
cmdline.cmdline_block_show = function (lines)
	cmdline.set_state({
		lines = lines,
	});

	cmdline.__render();
end

--- Added new line to the block.
---@param line any
cmdline.cmdline_block_append = function (line)
	local old = cmdline.get_state("lines", {});
	table.insert(old, line);

	cmdline.set_state({
		lines = old,
	});

	cmdline.__render();
end

--- Exited cmdline block.
cmdline.cmdline_block_hide = function ()
	cmdline.set_state({
		lines = {},
	});
	cmdline.state.lines = nil;

	cmdline.cmdline_hide();
end

------------------------------------------------------------------------------

--- Handles command-line events.
---@param event string
---@param ... any
cmdline.handle = function (event, ...)
	local _, err = pcall(cmdline[event], ...);
	if not err then
		return;
	end

	table.insert(log.entries, string.format("Error: %s", err));
end

--- Sets up the cmdline module.
cmdline.setup = function ()
	cmdline.__prepare();

	cmdline.window = vim.api.nvim_open_win(cmdline.buffer, false, {
		relative = "editor",

		row = 0,
		col = 0,

		width = 1,
		height = 1,

		hide = true
	});
	vim.wo[cmdline.window].sidescrolloff = math.floor(vim.o.columns * 0.5) or 36;
end

return cmdline;

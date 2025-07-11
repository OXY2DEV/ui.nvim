local utils = {};
-- local log = require("ui.log")

--- Wraps text by width.
---@param lines string[]
---@param width integer
---@return string[]
utils.text_wrap = function(lines, width)
	---|fS

	local wrapped = {};

	local function wrap_line (line)
		local _line = line;
		local tokens = {};

		while string.match(_line, "%s+") or string.match(_line, "^%S+") do
			if string.match(_line, "^%s+") then
				table.insert(tokens, string.match(_line, "^%s+"));
				_line = string.gsub(_line, "^%s+", "");
			else
				table.insert(tokens, string.match(_line, "^%S+"));
				_line = string.gsub(_line, "^%S+", "");
			end
		end

		local output = {};

		for _, token in ipairs(tokens) do
			local last = output[#output];

			if #token >= width then
				local times = math.max(vim.fn.strchars(token) / width);

				for _t = 0, times - 1, 1 do
					table.insert(output, vim.fn.strcharpart(token, _t * width, (_t + 1) * width));
				end

				-- Non-whitespace token larger then width.
				-- divided into lines.
			elseif not last then
				table.insert(output, token);

				-- No last line. Create new line.
			elseif (#last + #token) >= width then
				table.insert(output, token);

				-- Non-whitespace token that would result
				-- in a new line.
			elseif #last + #token <= width then
				output[#output] = last .. token;
			end
		end

		return output;
	end

	for _, line in ipairs(lines) do
		vim.list_extend(wrapped, wrap_line(line));
	end

	return wrapped;

	---|fE
end

--- Gets length of virtual text.
---@param virt_text [ string, string | nil ][]
---@return integer
utils.virt_len = function (virt_text)
	---|fS

	local len = 0;

	for _, part in ipairs(virt_text) do
		len = len + vim.fn.strdisplaywidth(part[1]);
	end

	return len;

	---|fE
end

--- Virtual text → statuscolumn text.
---@param virt_text? [ string, string? ][]
---@return string
utils.to_statuscolumn = function (virt_text)
	---|fS

	if vim.islist(virt_text) == false then
		return "";
	end

	local output = "";

	for e, entry in ipairs(virt_text) do
		if type(entry[2]) == "string" then
			if e == #virt_text then
				-- The final element shouldn't end
				-- with a highlight group reset.
				--
				-- This is for when the statuscolumn
				-- is wider then this line.
				output = output .. string.format("%%#%s#%s", entry[2], entry[1]);
			else
				output = output .. string.format("%%#%s#%s%%#Normal#", entry[2], entry[1]);
			end
		else
			output = output .. entry[1];
		end
	end

	return output;

	---|fE
end

--- Strips text from virtual text.
---@param virt_text [ string, string? ][]
---@return [ string, string? ][]
utils.strip_text = function (virt_text)
	---|fS

	if vim.islist(virt_text) == false then
		return {};
	end

	local new = {};

	for _, item in ipairs(virt_text) do
		table.insert(new, {
			string.rep(" ", vim.fn.strdisplaywidth(item[1])),
			item[2]
		});
	end

	return new;

	---|fE
end

---@param virt_lines ( [ string, string? ][] )[]
---@return string[]
---@return table
utils.process_virt = function (virt_lines)
	---|fS

	local lines, extmarks = {}, {};

	for _, line in ipairs(virt_lines) do
		table.insert(lines, "");
		table.insert(extmarks, {});

		for _, entry in ipairs(line) do
			if type(entry[2]) == "string" then
				table.insert(extmarks[#extmarks], {
					#lines[#lines],
					#(lines[#lines] .. entry[1]),
					entry[2]
				});
			end

			lines[#lines] = lines[#lines] .. entry[1];
		end
	end

	return lines, extmarks;

	---|fE
end

--- Processes UI contents.
---@param content [ integer, string ][]
---@return string[]
---@return ui.cmdline.decorations
utils.process_content = function (content)
	---|fS

	local lines = {};
	local extmarks = {};

	local X = 0;

	--- Handles a part of {content}.
	---@param part [ integer, string ]
	local function handle_part(part)
		---|fS

		if #extmarks == 0 then
			table.insert(extmarks, {});
			table.insert(lines, part[2]);
		else
			lines[#lines] = lines[#lines] .. part[2];
		end

		table.insert(extmarks[#extmarks], {
			X,
			X + #part[2],
			utils.attr_to_hl(part[3] or part[1])
		});
		X = X + #part[2];

		---|fE
	end

	--- Handles a part of {content} containing
	--- newlines.
	---@param part [ integer, string ]
	local function handle_newline(part)
		---|fS

		local _lines = vim.split(part[2], "\n", {});

		for l, line in ipairs(_lines) do
			if l == 1 and #lines > 0 then
				lines[#lines] = lines[#lines] .. line;
				table.insert(extmarks[#extmarks], { X, X + #line, utils.attr_to_hl(part[3] or part[1]) });

				X = X + #line;
			else
				table.insert(lines, line);
				table.insert(extmarks, {
					{ 0, #line, utils.attr_to_hl(part[3] or part[1]) }
				});

				X = #line;
			end
		end

		---|fE
	end

	for _, entry in ipairs(content) do
		if string.match(entry[2], "\n") then
			handle_newline(entry);
		else
			handle_part(entry);
		end
	end

	return lines, extmarks;

	---|fE
end

--- Processes UI contents.
---@param content [ integer, string ][]
---@return string[]
utils.to_lines = function (content)
	---|fS

	local lines = {};

	--- Handles a part of {content}.
	---@param part [ integer, string ]
	local function handle_part(part)
		---|fS

		if #lines == 0 then
			table.insert(lines, part[2]);
		else
			lines[#lines] = lines[#lines] .. part[2];
		end

		---|fE
	end

	--- Handles a part of {content} containing
	--- newlines.
	---@param part [ integer, string ]
	local function handle_newline(part)
		---|fS

		for l, line in ipairs(vim.split(part[2], "\n", { trimempty = false })) do
			if l == 1 and #lines > 0 then
				lines[#lines] = lines[#lines] .. line;
			else
				table.insert(lines, line);
			end
		end

		---|fE
	end

	for _, entry in ipairs(content) do
		if string.match(entry[2], "\n") then
			handle_newline(entry);
		else
			handle_part(entry);
		end
	end

	return lines;

	---|fE
end

---@param lines string[]
---@return integer
utils.max_len = function (lines)
	---|fS

	local W = 1;

	for _, line in ipairs(lines) do
		W = math.max(vim.fn.strchars(line), W);
	end

	return W;

	---|fE
end

--- Turns attribute ID to highlight group.
---@param attr integer
---@return string
utils.attr_to_hl = function (attr)
	return vim.fn.synIDattr(vim.fn.synIDtrans(attr), "name")
end

--- Creates list of confirm keys.
---@param prompt? string
---@param _? [ integer, string ][]
utils.confirm_keys = function (prompt, _)
	---|fS

	if prompt then
		-- You can hit `<CR>` to confirm the default
		-- action.
		-- You can hit `<ESC>` to cancel the action.
		local keys = { "\r", "\27" };

		for key in string.gmatch(prompt, "[%[%(](.)[%]%)]") do
			table.insert(keys, string.lower(key));
		end

		vim.g.__confirm_keys = keys;
	end

	---|fE
end

---@type integer, integer Buffer & window used for checking wrapped line height.
utils.__wrapped_buf, utils.__wrapped_win = nil, nil;

--- Gets line number for wrapped text.
---@param lines string[]
---@param width? integer
---@return integer
utils.wrapped_height = function(lines, width)
	---|fS

	width = width or vim.o.columns;

	if type(utils.__wrapped_buf) ~= "number" or vim.api.nvim_buf_is_valid(utils.__wrapped_buf) == false then
		utils.__wrapped_buf = vim.api.nvim_create_buf(false, true);
	end

	local win_config = {
		hide = true,
		relative = "editor",

		row = 5,
		col = 5,

		width = width,
		height = #lines,

		style = "minimal",
	};

	if type(utils.__wrapped_win) ~= "number" or vim.api.nvim_win_is_valid(utils.__wrapped_win) == false then
		utils.__wrapped_win = vim.api.nvim_open_win(utils.__wrapped_buf, false, win_config);
	else
		vim.api.nvim_win_set_config(utils.__wrapped_win, win_config);
	end

	vim.wo[utils.__wrapped_win].wrap = true;
	vim.wo[utils.__wrapped_win].linebreak = true;
	vim.wo[utils.__wrapped_win].breakindent = true;

	pcall(vim.api.nvim_buf_set_lines, utils.__wrapped_buf, 0, -1, false, lines);

	local text_height = vim.api.nvim_win_text_height(utils.__wrapped_win, { start_row = 0, end_row = -1 });
	return text_height.all;

	---|fE
end

--- Gets data type of given string.
---@param str string
---@return "constant" | "number" | "boolean" | "string"
utils.get_type = function (str)
	if not str then
		return "constant";
	elseif tonumber(str) then
		return "number";
	elseif str == "true" or str == "false" then
		return "boolean";
	else
		return "string";
	end
end

---@param lines string[]
---@return integer
utils.read_time = function (lines)
	---|fS

	--- Gets line complexity.
	---@param line string
	---@return number
	---@return integer
	local function line_complexity (line)
		---|fS

		local line_count = #vim.split(line, "[%?%!%.%;]", { trimempty = true });
		local words = vim.split(line, " ", { trimempty = true });

		local total_word_length = 0;

		for _, word in ipairs(words) do
			total_word_length = total_word_length + vim.fn.strchars(word);
		end

		local avg_word_per_sentence = #words / line_count;
		local avg_word_length = total_word_length / #words;

		return (avg_word_per_sentence * avg_word_length) / 10, #words;

		---|fE
	end

	local duration = 0;

	for _, line in ipairs(lines) do
		if string.match(line, "^%s*$") then
			goto continue;
		end

		local complexity, word_count = line_complexity(line);
		local WPM = 150 / complexity;

		duration = duration + (( word_count / WPM ) * 60 * 100);

	    ::continue::
	end

	return duration;

	---|fE
end

--- Creates a table row.
---@param parts [ string, string? ][]
---@return string
---@return table
utils.to_row = function (parts)
	---|fS

	local X = 0;
	local output = "";
	local extmarks = {};

	for _, part in ipairs(parts) do
		output = output .. part[1];

		if part[2] then
			table.insert(extmarks, { X, X + #part[1], part[2] });
		end

		X = X + #part[1];
	end

	return output, extmarks;

	---|fE
end

--- Gets the last window the user was in.
---@return integer
utils.last_win = function ()
	return vim.fn.win_getid(vim.fn.winnr("#"));
end

--- Evaluates `val`
---@param val any
---@param ... any
---@return any
utils.eval = function (val, ...)
	---|fS

	if type(val) ~= "function" then
		return val;
	end

	local can_call, new_val = pcall(val, ...);

	if can_call == false then
		return;
	else
		return new_val;
	end

	---|fE
end

---@param path string
---@return string
utils.path = function (path)
	---|fS

	local stat = vim.uv.fs_stat(path);

	if not stat then
		return path;
	elseif stat.type == "directory" then
		return vim.fn.fnamemodify(path, ":~:.");
	else
		return path;
	end

	---|fE
end

--- Sets buffer, window & global options.
---@param mode "b" | "w" | ""
---@param src integer
---@param name string
---@param value any
utils.set = function (mode, src, name, value)
	---|fS "fix: Sets given option, if it isn't set"
	--- `pcall()` is used for invalid buffer,
	--- window & option name errors.

	pcall(function ()
		if mode == "w" then
			local old = vim.wo[src][name]

			if old ~= value then
				vim.wo[src][name] = value;
			end
		elseif mode == "b" then
			local old = vim.bo[src][name]

			if old ~= value then
				vim.bo[src][name] = value;
			end
		else
			local old = vim.o[src][name]

			if old ~= value then
				vim.o[src][name] = value;
			end
		end
	end);

	---|fE
end

--- Trims leading & trailing empty lines.
---@param lines string[]
---@return string[]
utils.trim_lines = function (lines)
	---|fS

	local start, stop = 1, #lines;

	for l = 1, #lines, 1 do
		if string.match(lines[l] or "", "%S") then
			start = l;
			break;
		end
	end

	for l = #lines, 1, -1 do
		if string.match(lines[l] or "", "%S") then
			stop = l;
			break;
		end
	end

	local trimmed = {};

	for l = start, stop, 1 do
		table.insert(trimmed, lines[l]);
	end

	return trimmed;

	---|fE
end

--- Checks if a line is in the format of `:hi`.
---@param line string
---@return boolean
---@return table
utils.is_hl_line = function (line)
	---|fS

	local data = {
		group_name = nil,
		value = {},
	};

	if string.match(line, "([a-zA-Z0-9_.@-]+) +xxx links to ([a-zA-Z0-9_.@-]+)$") then
		-- @constant      xxx links to Constant
		local group, link = string.match(line, "([a-zA-Z0-9_.@-]+) +xxx links to ([a-zA-Z0-9_.@-]+)$");

		data.group_name = group;
		data.value.link = link;
	elseif string.match(line, "([a-zA-Z0-9_.@-]+) +xxx (.+)$") then
		-- Cursor         xxx guifg=#1e1e2e guibg=#f5e0dc
		local group, properties = string.match(line, "([a-zA-Z0-9_.@-]+) +xxx (.+)$");

		data.group_name = group;

		data.value.ctermfg = string.match(properties, "ctermfg=(%S+)");
		data.value.ctermbg = string.match(properties, "ctermbg=(%S+)");

		data.value.start = string.match(properties, "start=(%S+)");
		data.value.stop = string.match(properties, "stop=(%S+)");

		data.value.font = string.match(properties, "font=(%S+)");

		data.value.guifg = string.match(properties, "guifg=(%S+)");
		data.value.guibg = string.match(properties, "guibg=(%S+)");
		data.value.guisp = string.match(properties, "guisp=(%S+)");

		data.value.blend = string.match(properties, "blend=(%d+)");

		if string.match(properties, "cterm=(%S+)") then
			data.value.cterm = vim.split(
				string.match(properties, "cterm=(%S+)"),
				",",
				{ trimempty = true }
			);
		end

		if string.match(properties, "gui=(%S+)") then
			data.value.gui = vim.split(
				string.match(properties, "gui=(%S+)"),
				",",
				{ trimempty = true }
			);
		end
	end

	return data.group_name ~= nil, data;

	---|fE
end

return utils;

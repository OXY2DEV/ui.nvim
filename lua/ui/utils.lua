local utils = {};
-- local log = require("ui.log")

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
---@return integer[]
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

		table.insert(extmarks[#extmarks], { X, X + #part[2], utils.attr_to_hl(part[3] or part[1]) });
		X = X + #part[2];

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
				table.insert(extmarks[#extmarks], { X, X + #line, utils.attr_to_hl(part[3] or part[1]) });

				X = 0;
			else
				table.insert(lines, line);
				table.insert(extmarks, {
					{ 0, #line, utils.attr_to_hl(part[3] or part[1]) }
				});

				X = X + #line;
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
---@param content? [ integer, string ][]
utils.confirm_keys = function (prompt, content)
	---|fS

	if not prompt and not content then
		vim.g.__confirm_keys = {};
	elseif prompt then
		local keys = {};

		for key in string.gmatch(prompt, "[%[%(](.)[%]%)]") do
			table.insert(keys, string.lower(key));
		end

		vim.g.__confirm_keys = keys;
	end

	---|fE
end

--- Gets line number for wrapped text.
---@param lines string[]
---@param width? integer
---@return integer
utils.wrapped_height = function (lines, width)
	---|fS

	width = width or vim.o.columns;
	local height = 0;

	for _, line in ipairs(lines) do
		local len = vim.fn.strchars(line);

		if len <= width then
			height = height + 1;
		else
			height = height + math.floor(vim.fn.strchars(line) / width);

			if vim.fn.strchars(line) % width ~= 0 then
				height = height + 1;
			end
		end
	end

	return height;

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

return utils;

local utils = {};

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

		for l, line in ipairs(vim.split(part[2], "\n", { trimempty = true })) do
			if l == 1 and #lines > 0 then
				lines[#lines] = lines[#lines] .. line;
				table.insert(extmarks[#extmarks], { X, X + #line, utils.attr_to_hl(part[3] or part[1]) });

				X = 0;
			else
				table.insert(lines, line);
				table.insert(extmarks, {
					{ 0, #line, utils.attr_to_hl(part[3] or part[1]) }
				});
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

		for l, line in ipairs(vim.split(part[2], "\n", { trimempty = true })) do
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

return utils;

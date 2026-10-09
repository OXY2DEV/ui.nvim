local modifiers = {};
local utils = require("ui.utils");

modifiers.lpeg = {
	ls = vim.lpeg.Ct(
		vim.lpeg.P(" ") ^ 0 *
		vim.lpeg.Cg(
			vim.lpeg.R("09") ^ 1,
			"buffer_id"
		) *
		vim.lpeg.P(" ") ^ 0 *
		vim.lpeg.Cg(
			vim.lpeg.S("u%#ah-=RF?+x ") ^ 1 / function(str) return string.gsub(str, "%s*$", ""); end,
			"indicators"
		) *
		vim.lpeg.P(" ") ^ 0 *
		vim.lpeg.P('"') *
		vim.lpeg.Cg(
			(1 - vim.lpeg.P('"')) ^ 0,
			"name"
		) *
		vim.lpeg.P('"') *
		vim.lpeg.P(" ") ^ 0 *
		vim.lpeg.P("line") *
		vim.lpeg.P(" ") ^ 0 *
		vim.lpeg.Cg(
			vim.lpeg.R("09") ^ 1,
			"line"
		)
	),
};

modifiers.is_ls = function (msg, lines, _)
	if msg.kind ~= "list_cmd" then
		return false;
	elseif not modifiers.lpeg.ls:match(lines[1] or "") then
		return false;
	end

	return true;
end

modifiers.ls = function (_, lines)
	local _lines, exts = {}, {};
	local entries = {};

	---@type table<string, integer>
	local widths = {
		id = 6,
		name = 6,
		lnum = 4,
		indicators = 10
	};

	for l, line in ipairs(lines) do
		if #lines > 1 and l == 1 then
			goto continue;
		end

		local matches = modifiers.lpeg.ls:match(line);
		local entry = {
			id = matches.buffer_id or "",
			name = matches.name or "",
			lnum = matches.line or "",

			indicators = matches.indicators or "",
		};

		table.insert(entries, entry);

		widths.id = math.max(widths.id, vim.fn.strdisplaywidth(entry.id));
		widths.name = math.max(widths.name, vim.fn.strdisplaywidth(entry.name));
		widths.lnum = math.max(widths.lnum, vim.fn.strdisplaywidth(entry.lnum));
		widths.indicators = math.max(widths.indicators, vim.fn.strdisplaywidth(entry.indicators));

		::continue::
	end

	local title, title_exts = utils.to_row({
		{
			string.format(" %-" .. widths.id .. "s ", "Buffer"),
			"UILSBuffer"
		},
		{
			string.format(" %-" .. widths.name .. "s ", "Name"),
			"UILSBufname"
		},
		{
			string.format(" %-" .. widths.indicators .. "s ", "Indicators"),
			"UILSIndicator"
		},
		{
			string.format(" %-" .. widths.lnum .. "s ", "Line"),
			"UILSLmum"
		},
	});

	table.insert(_lines, title);
	table.insert(exts, title_exts);

	for e, entry in ipairs(entries) do
		local row, row_exts = utils.to_row({
			{
				string.format(" %-" .. widths.id .. "s ", entry.id),
				e % 2 == 0 and "@comment" or "UICmdlineSearchDown"
			},
			{
				string.format(" %-" .. widths.name .. "s ", entry.name),
				e % 2 == 0 and "@comment" or "UICmdlineDefault"
			},
			{
				string.format(" %-" .. widths.indicators .. "s ", entry.indicators),
				e % 2 == 0 and "@comment" or "UICmdlineLua"
			},
			{
				string.format(" %-" .. widths.lnum .. "s ", entry.lnum),
				e % 2 == 0 and "@comment" or "UICmdlineSubstitute"
			},
		});

		table.insert(_lines, row);
		table.insert(exts, row_exts);
	end

	return { lines = _lines, extmarks = exts };
end

return modifiers;

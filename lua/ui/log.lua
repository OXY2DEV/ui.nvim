local log = {};

log.kinds = {
	default = "󰛱 ",

	info = "i ",
	hint = "h ",
	warn = "w ",
	["error"] = "e ",
	log = "l ",

	debug = "d "
};

log.entries = {};

---@type integer Indentation level of log.
log.level = 0;

log.verbose = false;

log.export = function (path, verbose)
	verbose = verbose or log.verbose;

	local file = io.open(path or "log.log", "w");
	if not file then return; end

	for _, entry in ipairs(log.entries) do
		if type(entry) == "string" then
			-- Handle old log messages.
			file:write(string.rep(" ", 2 * log.level));
			file:write(entry, "\n");
		elseif entry.kind ~= "debug" or verbose == true then
			-- Handle new log messages.
			local msg = type(entry.msg) ~= "string" and vim.inspect(entry.msg) or entry.msg;
			local lines = vim.split(msg or "", "\n", { trimempty = true });

			if verbose then
				if entry.from then
					table.insert(lines, 1, string.format(
						"From: %s",
						entry.from
					));
				end
			end

			for l, line in ipairs(lines) do
				file:write(string.rep(" ", 2 * (entry.level or 0)));

				if l == 1 then
					file:write(log.kinds[entry.kind or "default"] or "");
				elseif l == #lines then
					file:write("  ");
				else
					file:write("  ");
				end

				file:write(line, "\n");
			end
		end
	end

	file:close();
end

--- Like `assert()`.
---@param from string
---@param value any
---@param message string
log.assert = function (from, value, message)
	if value == false then
		table.insert(log.entries, {
			kind = "error",
			level = log.level,

			msg = message or "Assertion failed",
			from = from
		});
	end
end

log.level_inc = function ()
	log.level = log.level + 1;
end

log.level_dec = function ()
	log.level = log.level - 1;
end

log.print = function (msg, from, kind)
	table.insert(log.entries, {
		kind = kind or "log",
		msg = msg,

		level = log.level,
		from = tostring(from)
	});
end

return log;

local log = {};

log.entries = {};

---@type integer Indentation level of log.
log.level = 0;

log.export = function (path)
	local file = io.open(path or "log.log", "w");
	if not file then return; end

	for _, entry in ipairs(log.entries) do
		if type(entry) == "string" then
			file:write(string.rep(" ", vim.o.tabstop * log.level));
			file:write(entry, "\n");
		else
			local msg = type(entry.msg) ~= "string" and vim.inspect(entry.msg) or entry.msg;

			for _, line in ipairs(vim.split(msg or "", "\n", {})) do
				file:write(string.rep(" ", vim.o.tabstop * (entry.level or 0)));
				file:write(line, "\n");
			end
		end
	end

	file:close();
end

--- Like `assert()`.
---@param val boolean
---@param msg? string
log.assert = function (val, msg)
	if val == false and type(msg) == "string" then
		table.insert(log.entries, {
			kind = "assert",
			msg = msg,

			level = log.level
		});
	end
end

log.level_inc = function ()
	log.level = log.level + 1;
end

log.level_dec = function ()
	log.level = log.level - 1;
end

log.print = function (msg, kind)
	kind = kind or "print";

	table.insert(log.entries, {
		kind = kind,
		msg = msg,
		level = log.level
	});
end

return log;

local log = {};

log.entries = {};

log.export = function (path)
	local file = io.open(path or "log.log", "w");
	if not file then return; end

	for _, entry in ipairs(log.entries) do
		file:write(entry .. "\n");
	end

	file:close();
end

--- Like `assert()`.
---@param val boolean
---@param msg? string
log.assert = function (val, msg)
	if val == false and type(msg) == "string" then
		table.insert(log.entries, msg);
	end
end

return log;

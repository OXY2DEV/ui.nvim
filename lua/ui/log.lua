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

return log;

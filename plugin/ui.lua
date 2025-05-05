-- This needs to be immediately called
-- otherwise start errors will get ignored.
require("ui").setup({});

vim.api.nvim_create_autocmd("VimEnter", {
	callback = function ()
		require("ui.highlight").setup();
		local log = require("ui.log");
		-- vim.g.__ui_dev = true;

		log.print("Attached to UI!", "plugin/ui.lua", "log");
		log.level_inc();
	end
});

vim.api.nvim_create_autocmd("VimLeave", {
	callback = function ()
		local log = require("ui.log");

		log.level_dec();
		log.print("Exporting log!", "plugin/ui.lua", "log");

		if vim.g.__ui_dev then
			log.export();
		end
	end
});

vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function ()
		require("ui.highlight").setup();
	end
})

local sub_commands = {
	"enable", "disable", "toggle",
	"clear",

	"log"
};

vim.api.nvim_create_user_command("UI", function (data)
	---@type string[]
	local args = data.fargs or {};

	pcall(require("ui").actions[args[1] or "toggle"]);
end, {
	nargs = "?",
	complete = function (_, cmdline, cursor_pos)
		---@type string
		local before = string.sub(cmdline, 0, cursor_pos);
		---@type string[]
		local tokens = vim.split(before, " ", { trimempty = true });

		if #tokens == 1 then
			return sub_commands;
		elseif #tokens == 2 and string.match(before, "%S$") then
			local completions = {};

			for _, cmd in ipairs(sub_commands) do
				if string.match(cmd, tokens[2]) then
					table.insert(completions, cmd);
				end
			end

			return completions;
		else
			return {};
		end
	end,
});

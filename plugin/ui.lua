vim.api.nvim_create_autocmd("VimEnter", {
	callback = function ()
		local log = require("ui.log");
		-- vim.g.__ui_dev = true;

		require("ui").setup();
		require("ui.highlight").setup();

		log.print("Attached to UI");
		log.level_inc();
	end
});

vim.api.nvim_create_autocmd("VimLeave", {
	callback = function ()
		local log = require("ui.log");

		log.level_dec();
		log.print("Exporting log");

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


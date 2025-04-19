vim.api.nvim_create_autocmd("VimEnter", {
	callback = function ()
		require("ui").setup();
		require("ui.highlight").setup();
	end
});

vim.api.nvim_create_autocmd("VimLeave", {
	callback = function ()
		if vim.g.__ui_dev then
			require("ui.log").export();
		end
	end
});

vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function ()
		require("ui.highlight").setup();
	end
})


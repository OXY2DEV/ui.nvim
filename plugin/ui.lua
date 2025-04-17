require("ui").setup();
require("ui.highlight").setup();

vim.api.nvim_create_autocmd("VimLeave", {
	callback = function ()
		require("ui.log").export();
	end
});

vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function ()
		require("ui.highlight").setup();
	end
})


local spec = {};
local log = require("ui.log")

spec.default = {
	cmdline = {
		styles = {
			default = {
				winhl = "Normal:Color4T",

				filetype = "vim",
				offset = 0,

				icon = { { "  " } },
				--
				-- title = {
				-- 	{
				-- 		{ "Run", "Special" }
				-- 	}
				-- }
			},

			prompt = {
				condition = function (state)
					return state.prompt ~= "";
				end,

				title = function (state)
					return {
						{
							{ state.prompt, "Comment" }
						}
					}
				end
			}
		}
	}
};

spec.config = vim.deepcopy(spec.default);

spec.get_cmdline_config = function (state, lines)
	---|fS

	local styles = spec.config.cmdline.styles or {};
	local _output = styles.default or {};

	---@type string[]
	local keys = vim.tbl_keys(styles);
	table.sort(keys);

	--- Iterate over keys and get the first
	--- match.
	for _, key in ipairs(keys) do
		if key == "default" then goto continue; end
		local entry = styles[key] or {};
		local can_validate, valid = pcall(entry.condition, state, lines);

		if can_validate and valid ~= false then
			_output = vim.tbl_extend("force", _output, entry);
			break;
		end

	    ::continue::
	end

	local output = {};

	--- Turn dynamic values into static
	--- values
	for k, v in pairs(_output) do
		if type(v) ~= "function" then
			output[k] = v;
		elseif k ~= "condition" then
			local can_run, val = pcall(v, state, lines);

			if can_run and val ~= nil then
				output[k] = val;
			end
		end
	end

	return output;

	---|fE
end

return spec;

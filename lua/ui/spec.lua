local spec = {};
local log = require("ui.log")

spec.default = {
	cmdline = {
		styles = {
			default = {
				winhl = "Normal:Color4T",

				filetype = "vim",
				offset = 0,

				icon = { { "  ", "Color4" } },
				--
				-- title = {
				-- 	{
				-- 		{ "Run", "Special" }
				-- 	}
				-- }
			},

			lua = {
				condition = function (_, lines)
					return string.match(lines[#lines], "^lua") ~= nil;
				end,

				offset = 4,

				icon = { { "  ", "Color4" } },
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
	},

	message = {
		confirm = {
			default = {
				width = function (_, lines)
					local w;

					for _, line in ipairs(lines) do
						if w == nil or vim.fn.strdisplaywidth(line) > w then
							w = vim.fn.strdisplaywidth(line);
						end
					end

					return w;
				end,

				height = function (_, lines)
					return #lines;
				end,

				row = function (_, lines)
					return math.ceil((vim.o.lines - #lines) / 2);
				end,

				col = function (_, lines)
					local w;

					for _, line in ipairs(lines) do
						if not w or vim.fn.strdisplaywidth(line) > w then
							w = vim.fn.strdisplaywidth(line);
						end
					end

					return math.ceil((vim.o.columns - w) / 2);
				end,

				winhl = "Normal:Normal"
			},
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
			else
				output[k] = nil;
			end
		end
	end

	return output;

	---|fE
end

spec.get_confirm_config = function (msg, lines)
	---|fS

	local styles = spec.config.message.confirm or {};
	local _output = styles.default or {};

	---@type string[]
	local keys = vim.tbl_keys(styles);
	table.sort(keys);

	--- Iterate over keys and get the first
	--- match.
	for _, key in ipairs(keys) do
		if key == "default" then goto continue; end
		local entry = styles[key] or {};
		local can_validate, valid = pcall(entry.condition, msg, lines);

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
			local can_run, val = pcall(v, msg, lines);

			if can_run and val ~= nil then
				output[k] = val;
			else
				output[k] = nil;
			end
		end
	end

	return output;

	---|fE
end

return spec;

local spec = {};
local log = require("ui.log")

local utils = require("ui.utils");

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

			lua_eval = {
				condition = function (_, lines)
					return string.match(lines[#lines], "^=") ~= nil;
				end,

				offset = 1,
				filetype = "lua",

				icon = { { "  ", "Color4" } },
			},

			lua = {
				condition = function (_, lines)
					return string.match(lines[#lines], "^lua") ~= nil;
				end,

				offset = 4,
				filetype = "lua",

				icon = { { "  ", "Color4" } },
			},

			keymap = {
				condition = function (state)
					return string.match(state.prompt or "", "[%[%(].[%]%)]") ~= nil;
				end,

				title = function (state)
					local title = {};
					local is_first = true;

					for key, command in string.gmatch(state.prompt, "[%[%(](.)[%]%)](%S*)") do
						table.insert(title, {
							{ " 󰧹 " .. (key or ""), is_first and "DiagnosticHint" or "Comment" },
							{ " → " .. string.upper(key or "") .. string.gsub(command or "", "%W$", ""), "Comment" }
						});

						if is_first then
							is_first = false;
						end
					end

					return title;
				end,

				winhl = ""
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
		processors = {
			default = {
				duration = function (msg, lines)
					local duration = 1500;

					if msg.kind == "write" then
						--- Write messages run frequently.
						--- Reduce duration.
						duration = 1000;
					elseif msg.kind == "confirm" then
						--- Currently not in use.
						duration = 2000;
					elseif vim.list_contains({ "emsg", "echoerr", "lua_error", "rpc_error", "shell_err" }, msg.kind) then
						--- Error messages.
						duration = 2500;
					end

					return duration + utils.read_time(lines);
				end,
				decorations = {
					sign_text = "󰵅 ",
					sign_hl_group = "Comment",
					-- line_hl_group = "Comment"
				}
			},

			option = {
				condition = function (_, lines)
					return string.match(lines[1], "^%s+%w+=") ~= nil or string.match(lines[1], "^no%w+$") ~= nil;
				end,

				modifier = function (_, lines)
					if string.match(lines[1], "^no%w+$") then
						local key = string.match(lines[1], "^no(.*)$");

						return {
							lines = {
								string.format("%s: false", key)
							},
							extmarks = {
								{
									{ 0, #key, "@property" },
									{ #key, #key + 1, "@punctuation" },
									{ #key + 2, #key + 7, "@boolean" },
								}
							}
						};
					else
						local key, value = string.match(lines[1] or "", "^%s+(%w+)=(.*)$");

						if utils.get_type(value) == "string" then
							value = vim.inspect(value);
						end

						return {
							lines = {
								string.format("%s: %s", key, value)
							},
							extmarks = {
								{
									{ 0, #key, "@property" },
									{ #key, #key + 1, "@punctuation" },
									{ #key + 2, #key + 2 + #value, "@" .. utils.get_type(value) },
								}
							}
						};
					end
				end,
				decorations = {
					sign_text = "󰣖 ",
					sign_hl_group = "DiagnosticHint"
					-- line_hl_group = "DiagnosticVirtualTextHint"
				}
			},

			search = {
				condition = function (msg)
					return msg.kind == "search_cmd";
				end,

				modifier = function (_, lines)
					local term = string.match(lines[1], "^?(.*)$");

					return {
						lines = { term },
						extmarks = { {} }
					};
				end,
				decorations = {
					sign_text = " ",
					sign_hl_group = "Special"
					-- line_hl_group = "DiagnosticVirtualTextHint"
				}
			},

			lua_error = {
				condition = function (msg)
					return msg.kind == "lua_error";
				end,

				modifier = function (_, lines)
					if vim.g.__ui_history then
						return;
					end

					local path, line, actual_error = "", "", "";

					for _, _line in ipairs(lines) do
						if string.match(_line, "Error executing lua callback") then
							path, line, actual_error = string.match(_line, "Error executing lua callback: ([^:]-):(%d+): (.-)$");
							path = vim.fn.fnamemodify(path, ":~");
							break;
						end
					end

					return {
						lines = {
							actual_error,
							string.format("File: %s", path),
							string.format("Line: %s", line)
							-- text
						},
						extmarks = {
							{
								{ 0, #actual_error, "DiagnosticError" },
							},
							{
								{ 0, 5, "Comment" },
								{ 6, 6 + #path, "DiagnosticHint" },
							},
							{
								{ 0, 5, "Comment" },
								{ 6, 6 + #line, "DiagnosticHint" },
							},
						}
					}
				end,

				decorations = {
					sign_text = " ",
					sign_hl_group = "DiagnosticError",
					-- line_hl_group = "DiagnosticVirtualTextError",
				}
			},

			error_msg = {
				condition = function (msg)
					return msg.kind == "emsg";
				end,

				decorations = {
					sign_text = " ",
					sign_hl_group = "DiagnosticError"
					-- line_hl_group = "DiagnosticVirtualTextHint"
				}
			}

			-- echo = {
			-- 	condition = function (msg)
			-- 		return msg.kind == "echo";
			-- 	end,
			-- }
		},

		confirm = {
			default = {
				winhl = "Normal:Normal"
			},

			swap_alert = {
				condition = function (_, lines)
					return string.match(lines[2] or "", '^Swap') ~= nil
				end,

				modifier = {
					lines = { "󰾴 Swap file detected!" },
					extmarks = {
						{
							{ 0, 24, "Special" }
						}
					}
				},

				row = 0,
			},

			write_confirm = {
				condition = function (_, lines)
					return string.match(lines[2] or "", '^Save changes to "([^"]+)"') ~= nil
				end,

				modifier = function (_, lines)
					local file = string.match(lines[2] or "", 'Save changes to "([^"]+)"')

					return {
						lines = {
							string.format("󰽂 Save as  %s ?", file)
						},
						extmarks = {
							{
								{ 0, 13, "Comment" },
								{ 13, 15 + #file, "DiagnosticVirtualTextHint" },
								{ 15 + #file, 16 + #file, "Comment" },
							}
						}
					};
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

spec.get_msg_processor = function (msg, lines, extmarks)
	---|fS

	local processors= spec.config.message.processors or {};
	local _output = processors.default or {};

	---@type string[]
	local keys = vim.tbl_keys(processors);
	table.sort(keys);

	--- Iterate over keys and get the first
	--- match.
	for _, key in ipairs(keys) do
		if key == "default" then goto continue; end
		local entry = processors[key] or {};
		local can_validate, valid = pcall(entry.condition, msg, lines, extmarks);

		if can_validate and valid ~= false then
			_output = vim.tbl_extend("force", _output, entry);
			break;
		end

	    ::continue::
	end

	local output = {};

	---@param val any
	---@param ...? any
	---@return any
	local function get_val(val, ...)
		---|fS

		if type(val) == "function" then
			local can_call, new_val;

			if ... then
				can_call, new_val = pcall(val, ...);
			else
				can_call, new_val = pcall(val, msg, lines, extmarks);
			end

			return can_call and new_val or nil;
		else
			return val;
		end

		---|fE
	end

	--- Turn dynamic values into static
	--- values
	for k, v in pairs(_output) do
		if k == "duration" then
			local modified = get_val(_output.modifier);

			if modified then
				output.duration = get_val(v, msg, modified.lines or lines, modified.extmarks or extmarks);
			else
				output.duration = get_val(v);
			end
		else
			output[k] = get_val(v);
		end
	end

	return output;

	---|fE
end

return spec;

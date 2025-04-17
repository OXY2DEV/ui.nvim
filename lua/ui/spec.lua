local spec = {};
local log = require("ui.log")

local utils = require("ui.utils");

spec.default = {
	cmdline = {
		styles = {
			default = {
				---|fS

				winhl = "Normal:UICmdlineDefault",

				filetype = "vim",
				offset = 0,

				icon = { { "  ", "UICmdlineDefaultIcon" } },

				---|fE
			},

			search_up = {
				---|fS

				condition = function (state)
					return state.firstc == "/";
				end,

				winhl = "Normal:UICmdlineSearchUp",
				filetype = function ()
					return "text";
				end,

				icon = { { "  ", "UICmdlineSearchUpIcon" } },

				---|fE
			},

			search_down = {
				---|fS

				condition = function (state)
					return state.firstc == "?";
				end,

				winhl = "Normal:UICmdlineSearchDown",
				filetype = function ()
					return "text";
				end,

				icon = { { "  ", "UICmdlineSearchDownIcon" } },

				---|fE
			},

			set = {
				---|fS

				condition = function (_, lines)
					return string.match(lines[#lines], "^set ") ~= nil;
				end,

				winhl = "Normal:UICmdlineDefault",

				filetype = "vim",

				icon = {
					{ "  ", "UICmdlineDefaultIcon" }
				},

				---|fE
			},

			shell = {
				---|fS

				condition = function (_, lines)
					return string.match(lines[#lines], "^!") ~= nil;
				end,

				winhl = "Normal:UICmdlineEval",

				offset = 1,
				filetype = function (state)
					return state.pos < 1 and "vim" or "lua";
				end,

				icon = function ()
					if not _G.is_within_termux then
						return {
							{ "  ", "UICmdlineEvalIcon" }
						};
					elseif _G.is_within_termux() then
						return {
							{ " 󰀲 ", "UICmdlineEvalIcon" }
						};
					else
						return {
							{ " 󰀵 ", "UICmdlineEvalIcon" }
						};
					end
				end,

				---|fE
			},

			substitute = {
				---|fS

				condition = function (_, lines)
					return string.match(lines[#lines], "^%S*s/") ~= nil;
				end,

				winhl = "Normal:UICmdlineSubstitute",

				filetype = "vim",

				icon = function (_, lines)
					if string.match(lines[#lines], "^s/") then
						return {
							{ "  ", "UICmdlineSubstituteIcon" }
						};
					else
						return {
							{ "  ", "UICmdlineSubstituteIcon" }
						};
					end
				end,

				---|fE
			},

			lua_eval = {
				---|fS

				condition = function (_, lines)
					return string.match(lines[#lines], "^=") ~= nil;
				end,

				winhl = "Normal:UICmdlineEval",

				offset = 1,
				filetype = function (state)
					return state.pos < 1 and "vim" or "lua";
				end,

				icon = {
					{ "  ", "UICmdlineEvalIcon" }
				},

				---|fE
			},

			lua = {
				---|fS

				condition = function (_, lines)
					return string.match(lines[#lines], "^lua ") ~= nil;
				end,

				winhl = "Normal:UICmdlineLua",

				offset = 4,
				filetype = function (state)
					return state.pos < 4 and "vim" or "lua";
				end,

				icon = { { "  ", "UICmdlineLuaIcon" } },

				---|fE
			},

			keymap = {
				---|fS

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

				---|fE
			},

			zz_prompt = {
				---|fS

				condition = function (state)
					return state.prompt ~= "";
				end,

				title = function (state)
					local output = {};
					local lines = utils.text_wrap({ state.prompt or "" }, math.floor(vim.o.columns * 0.8));
					local hl = "UICmdlineLuaIcon";

					for l, line in ipairs(lines) do
						local _line = {};

						if l == 1 then
							table.insert(_line, { " ╭╴", hl });
						else
							table.insert(_line, { " │ ", hl });
						end

						table.insert(_line, { line, "Comment" });
						table.insert(output, _line);
					end

					return output;
				end,

				icon = { { " 󰘎 ", "UICmdlineLuaIcon" } },

				---|fE
			}
		}
	},

	message = {
		processors = {
			default = {
				---|fS

				duration = function (msg, lines)
					local duration = 2500;

					if msg.kind == "write" then
						--- Write messages run frequently.
						--- Reduce duration.
						duration = 2000;
					elseif msg.kind == "confirm" then
						--- Currently not in use.
						duration = 3000;
					elseif vim.list_contains({ "emsg", "echoerr", "lua_error", "rpc_error", "shell_err" }, msg.kind) then
						--- Error messages.
						duration = 3500;
					end

					return duration + utils.read_time(lines);
				end,
				decorations = function (msg)
					local config = {
						icon = {
							{ "▍", "UIMessageDefault" }
						}
					};

					if msg.content and #msg.content == 1 then
						local content = msg.content[1];
						local hl = utils.attr_to_hl(content[3]);

						if hl == "WarningMsg" then
							config.icon = {
								{ "▍ ", "UIMessageWarnSign" }
							};
							config.line_hl_group = "UIMessageWarn";
						elseif hl == "ErrorMsg" then
							config.icon = {
								{ "▍ ", "UIMessageErrorSign" }
							};
							config.line_hl_group = "UIMessageError";
						else
							config.icon = {
								{ "▍ ", "UIMessageInfoSign" }
							};
							config.line_hl_group = "UIMessageInfo";
						end
					end

					return config;
				end,

				---|fE
			},

			option = {
				---|fS

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
					icon = {
						{ "▍󰣖 ", "UIMessageHint" }
					},
					line_hl_group = "UIMessageHint"
				}

				---|fE
			},

			search = {
				---|fS

				condition = function (msg)
					return msg.kind == "search_cmd";
				end,

				modifier = function (_, lines)
					local term = string.match(lines[1], "^[%?/](.*)$");

					return {
						lines = { term },
						extmarks = {
							{}
						}
					};
				end,
				decorations = function (_, lines)
					if string.match(lines[#lines], "^/") then
						return {
							icon = {
								{ "▍ ", "UICmdlineSearchUpIcon" }
							},
							line_hl_group = "UICmdlineSearchUp"
						};
					else
						return {
							icon = {
								{ "▍ ", "UICmdlineSearchDownIcon" }
							},
							line_hl_group = "UICmdlineSearchDown"
						};
					end
				end

				---|fE
			},

			lua_error = {
				---|fS

				condition = function (_, lines)
					for _, line in ipairs(lines) do
						if string.match(line, ".-:%d+: ?.-$") then
							return true;
						end
					end

					return false;
				end,

				modifier = function (_, lines)
					if vim.g.__ui_history then
						return;
					end

					local path, line, actual_error = "", "", "";
					local exec, code;

					for _, _line in ipairs(lines) do
						if string.match(_line, "Error executing (.-):") then
							exec = string.match(_line, "Error executing (.-):");
						end

						if string.match(_line, ".-:%d+: ?.-$") then
							path, line, actual_error = string.match(_line, "(.-):(%d+): ?(.-)$");

							if string.match(path, "%[.-%]$") then
								path = string.match(path, "%[.-%]$");
							else
								path = vim.fn.fnamemodify(
									string.match(path, "%S+$"),
									":~"
								);
							end

							code = string.match(_line, "^E(%d%d+)")
							break;
						end
					end

					if actual_error == "" then
						return {};
					end

					return {
						lines = {
							actual_error,
							string.format("From: %s", path),
							string.format("Line: %s", line),
							(code or exec) and "" or nil,
							code and string.format("Code: %s", code) or nil,
							exec and string.format("Exec: %s", exec) or nil,
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
							(code or exec) and {} or nil,
							code and {
								{ 0, 5, "Comment" },
								{ 6, 6 + #code, "DiagnosticError" },
							} or nil,
							exec and {
								{ 0, 5, "Comment" },
								{ 6, 6 + #exec, "DiagnosticError" },
							} or nil,
						}
					};
				end,

				decorations = {
					icon = {
						{ "▍ ", "UIMessageErrorSign" }
					},
					padding = {
						{ "▍", "UIMessageErrorSign" }
					},
					line_hl_group = "UIMessageError",
				}

				---|fE
			},

			z_error_msg = {
				---|fS

				condition = function (msg)
					return msg.kind == "emsg";
				end,

				decorations = {
					icon = {
						{ "▍", "UIMessageErrorSign" }
					},
					padding = {
						{ "▍", "UIMessageErrorSign" }
					},

					line_hl_group = "UIMessageError"
				}

				---|fE
			},

			highlight_link = {
				---|fS

				condition = function (_, lines)
					return #lines == 2 and string.match(lines[2], "^.- +xxx links to .-") ~= nil;
				end,

				modifier = function (_, lines)
					local group_name, link = string.match(lines[2], "^(.-) +xxx links to (.-)$");
					group_name = string.gsub(group_name, "[^a-zA-Z0-9_.@-]", "");

					return {
						lines = {
							"abcABC 123",
							string.format("Group: %s", group_name),
							string.format("  Link: %s", link)
						},
						extmarks = {
							{
								{ 0, 10, group_name }
							},
							{
								{ 0, 7, "DiagnosticInfo" },
								{ 7, 7 + #group_name, "@label" }
							},
							{
								{ 2, 7, "@property" },
								{ 8, 8 + #link, "@constant" },
							}
						}
					}
				end,
				decorations = {
					icon = {
						{ "▍ ", "UIMessagePaletteSign" }
					},
					padding = {
						{ "▍", "UIMessagePaletteSign" }
					},
				}

				---|fE
			},

			highlight_group = {
				---|fS

				condition = function (_, lines)
					return #lines == 2 and string.match(lines[2], "^.- xxx links to .-") == nil and string.match(lines[2], "^.- +xxx") ~= nil;
				end,

				modifier = function (_, lines)
					local group_name, properties = string.match(lines[2], "^(%S+)%s+xxx%s(.-)$");
					group_name = string.gsub(group_name, "[^a-zA-Z0-9_.@-]", "");

					local _lines = {
						"abcABC 123",
						string.format("Group: %s", group_name),
					};
					local _extmarks = {
						{
							{ 0, #_lines[1], group_name }
						},
						{
							{ 0, 7, "DiagnosticInfo" },
							{ 7, 7 + #group_name, "@label" }
						},
					};

					for _, property in ipairs(vim.split(properties, " ")) do
						local name, value = string.match(property, "^(.-)=(.+)$");

						table.insert(_lines, string.format("  %s: %s", name, value));
						table.insert(_extmarks, {
							{ 2, 2 + #name, "@property" },
							{ 2 + #name, 2 + #name + 1, "Comment" },
							{ 2 + #name + 2, 2 + #name + 2 + #value, "@constant" },
						})
					end

					return {
						lines = _lines,
						extmarks = _extmarks
					};
				end,
				decorations = {
					icon = {
						{ "▍ ", "UIMessagePaletteSign" }
					},
					padding = {
						{ "▍", "UIMessagePaletteSign" }
					},
				}

				---|fE
			},

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

spec.get_cmdline_style = function (state, lines)
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

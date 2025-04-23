local spec = {};
local utils = require("ui.utils");

---@type ui.config
spec.default = {
	popupmenu = {
		---|fS

		enable = true,

		tooltip = function ()
			local mode = vim.api.nvim_get_mode().mode;
			return mode == "c" and {
				{ " 󰸾 󰹀 ", "UIMenuKeymap" },
			} or {
				{ " 󰹁 󰸽 ", "UIMenuKeymap" },
			};
		end,

		entries = {
			---|fS

			default = {
				padding_left = " ",
				padding_right = " ",

				icon = "󰘎 ",
				icon_hl = "Special",

				select_hl = "UIMenuSelect"
			},

			vim_variable = {
				condition = function (word)
					return string.match(word, "^v:");
				end,

				icon = " "
			},


			class = {
				condition = function (_, kind)
					return kind == "m";
				end,

				icon = " "
			},

			["function"] = {
				condition = function (_, kind)
					return kind == "f";
				end,

				icon = "󰡱 "
			},

			macro = {
				condition = function (_, kind)
					return kind == "d";
				end,

				icon = "󰕠 "
			},

			type_definiton = {
				condition = function (_, kind)
					return kind == "t";
				end,

				icon = " "
			},

			variable = {
				condition = function (_, kind)
					return kind == "v";
				end,

				icon = "󰏖 "
			},

			---|fE
		}

		---|fE
	},

	cmdline = {
		---|fS

		enable = true,

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
					---@diagnostic disable:undefined-field
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
					---@diagnostic enable:undefined-field
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
					---@type ( [ string, string? ][] )[]
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
					---@type ( [ string, string? ][] )[]
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

		---|fE
	},

	message = {
		---|fS

		enable = true,

		message_winconfig = {},
		confirm_winconfig = {},
		list_winconfig = {},
		history_winconfig = {},

		ignore = function (kind, content)
			---|fS

			if kind == "bufwrite" then
				local lines = utils.process_content(content);

				if string.match(lines[#lines], "written$") == nil then
					--- Ignore the first message after `:w`.
					return true;
				end
			end

			return false;

			---|fE
		end,

		msg_styles = {
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
							config.padding = {
								{ "▍  ", "UIMessageWarnSign" }
							};
							config.line_hl_group = "UIMessageWarn";
						elseif hl == "ErrorMsg" then
							config.icon = {
								{ "▍ ", "UIMessageErrorSign" }
							};
							config.padding = {
								{ "▍  ", "UIMessageErrorSign" }
							};
							config.line_hl_group = "UIMessageError";
						else
							config.icon = {
								{ "▍ ", "UIMessageInfoSign" }
							};
							config.padding = {
								{ "▍  ", "UIMessageInfoSign" }
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
					padding = {
						{ "▍  ", "UIMessageHint" }
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
							padding = {
								{ "▍  ", "UICmdlineSearchUpIcon" }
							},
							line_hl_group = "UICmdlineSearchUp"
						};
					else
						return {
							icon = {
								{ "▍ ", "UICmdlineSearchDownIcon" }
							},
							padding = {
								{ "▍  ", "UICmdlineSearchDownIcon" }
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
						return {};
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
						{ "▍  ", "UIMessageErrorSign" }
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
						{ "▍  ", "UIMessagePaletteSign" }
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
						{ "▍  ", "UIMessagePaletteSign" }
					},
				}

				---|fE
			},

			write = {
				---|fS

				condition = function (msg)
					return msg.kind == "bufwrite";
				end,

				modifier = function (_, lines)
					local filename, _, bytes;

					if string.match(lines[#lines], "%[New%]") then
						filename, _, bytes = string.match(lines[#lines], '^"(.+)" %[New%] (%d+)L, (%d+)B written$');
					else
						filename, _, bytes = string.match(lines[#lines], '^"(.+)" (%d+)L, (%d+)B written$');
					end

					return {
						lines = {
							string.format("Saved to %s!", filename),
							string.format("Wrote: %s Bytes", bytes)
						},
						extmarks = {
							{
								{ 0, 9, "Comment" },
								{ 9, 9 + #filename, "Special" },
								{ 9 + #filename, 10 + #filename, "Comment" }
							},
							{
								{ 0, 7, "Comment" },
								{ 7, 7 + #bytes, "@constant" },
								{ 8 + #bytes, 13 + #bytes, "Comment" }
							},
						}
					};
				end,

				decorations = {
					icon = {
						{ "▍󰳻 ", "UIMessageOk" }
					},
					padding = {
						{ "▍  ", "UIMessageOk" }
					},
				}

				---|fE
			}
		},

		is_list = function (kind)
			if kind ~= "list_cmd" then
				return false;
			end

			local invalid_commands = { "^highlight .+", "^hi .+", "^set .+" };
			local last_cmd = vim.fn.histget("cmd", -1);

			for _, pattern in ipairs(invalid_commands) do
				if string.match(last_cmd, pattern) then
					return false;
				end
			end

			return true;
		end,

		list_styles = {
			default = {},

			ls = {
				---|fS

				condition = function ()
					local last_cmd = vim.fn.histget("cmd", -1);

					for _, patt in ipairs({ "^ls", "^buffers", "^files" }) do
						if string.match(last_cmd, patt) then
							return true;
						end
					end

					return false;
				end,

				modifier = function (_, lines)
					local _lines, exts = {}, {};
					local entries = {};

					local widths = {
						id = 6,
						name = 6,
						lnum = 4,
						indicators = 10
					};

					for l, line in ipairs(lines) do
						if l == 1 then
							goto continue;
						end

						local ID, indicators, name, lnum = string.match(line, '^%s*(%d+)%s*([u%%#ah%-=RF%?%+x]+)%s*"(.+)"%s*line (%d+)$');

						table.insert(entries, {
							id = ID or "",
							name = name or "",
							lnum = lnum or "",

							indicators = indicators or "",
						});

						widths.id = math.max(widths.id, vim.fn.strdisplaywidth(ID or ""));
						widths.name = math.max(widths.name, vim.fn.strdisplaywidth(name or ""));
						widths.lnum = math.max(widths.lnum, vim.fn.strdisplaywidth(lnum or ""));
						widths.indicators = math.max(widths.indicators, vim.fn.strdisplaywidth(indicators or ""));

						::continue::
					end

					local title, title_exts = utils.to_row({
						{
							string.format(" %-" .. widths.id .. "s ", "Buffer"),
							"@attribute"
						},
						{ "╷", "@function" },
						{
							string.format(" %-" .. widths.name .. "s ", "Name"),
							"@attribute"
						},
						{ "╷", "@function" },
						{
							string.format(" %-" .. widths.indicators .. "s ", "Indicators"),
							"@attribute"
						},
						{ "╷", "@function" },
						{
							string.format(" %-" .. widths.lnum .. "s ", "Line"),
							"@attribute"
						},
					});

					table.insert(_lines, title);
					table.insert(exts, title_exts);

					for e, entry in ipairs(entries) do
						local border = e == #entries and "╵" or "│";

						local row, row_exts = utils.to_row({
							{
								string.format(" %-" .. widths.id .. "s ", entry.id),
								"Comment"
							},
							{ border, "@function" },
							{
								string.format(" %-" .. widths.name .. "s ", entry.name),
								"Comment"
							},
							{ border, "@function" },
							{
								string.format(" %-" .. widths.indicators .. "s ", entry.indicators),
								"Comment"
							},
							{ border, "@function" },
							{
								string.format(" %-" .. widths.lnum .. "s ", entry.lnum),
								"Comment"
							},
						});

						table.insert(_lines, row);
						table.insert(exts, row_exts);
					end

					return { lines = _lines, extmarks = exts };
				end

				---|fE
			},

			hi = {
				---|fS

				condition = function ()
					local last_cmd = vim.fn.histget("cmd", -1);

					for _, patt in ipairs({ "^hi%s*$", "^highlight%s*$" }) do
						if string.match(last_cmd, patt) then
							return true;
						end
					end

					return false;
				end,

				modifier = function (_, lines, exts)
					local _lines = vim.deepcopy(lines);
					local _exts = vim.deepcopy(exts);

					table.remove(_lines, 1);
					table.remove(_exts, 1);

					return { lines = _lines, extmarks = _exts };
				end

				---|fE
			},
		},

		confirm_styles = {
			default = {
				winhl = "Normal:Normal"
			},

			swap_alert = {
				---|fS

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

				---|fE
			},

			write_confirm = {
				---|fS

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

				---|fE
			}
		}

		---|fE
	}
};

---@type ui.config
spec.config = vim.deepcopy(spec.default);

--- Gets cmdline style.
---@param state ui.cmdline.state
---@param lines string[]
---@return ui.cmdline.style__static
spec.get_cmdline_style = function (state, lines)
	---|fS

	local styles = spec.config.cmdline.styles or {};
	---@type ui.cmdline.style
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

	---@type ui.cmdline.style__static
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

--- Gets confirmation message style.
---@param msg ui.message.entry
---@param lines string[]
---@param extmarks ui.message.extmarks
---@return ui.message.confirm__static
spec.get_confirm_style = function (msg, lines, extmarks)
	---|fS

	local styles = spec.config.message.confirm_styles or {};
	---@type ui.message.confirm
	local _output = styles.default or {};

	---@type string[]
	local keys = vim.tbl_keys(styles);
	table.sort(keys);

	--- Iterate over keys and get the first
	--- match.
	for _, key in ipairs(keys) do
		if key == "default" then goto continue; end
		local entry = styles[key] or {};
		local can_validate, valid = pcall(entry.condition, msg, lines, extmarks);

		if can_validate and valid ~= false then
			_output = vim.tbl_extend("force", _output, entry);
			break;
		end

	    ::continue::
	end

	---@type ui.message.confirm__static
	local output = {};

	--- Turn dynamic values into static
	--- values
	for k, v in pairs(_output) do
		if type(v) ~= "function" then
			output[k] = v;
		elseif k ~= "condition" then
			local can_run, val = pcall(v, msg, lines, extmarks);

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


--- Gets list message style.
---@param msg ui.message.entry
---@param lines string[]
---@param extmarks ui.message.extmarks
---@return ui.message.list__static
spec.get_listmsg_style = function (msg, lines, extmarks)
	---|fS

	local styles = spec.config.message.list_styles or {};
	---@type ui.message.list
	local _output = styles.default or {};

	---@type string[]
	local keys = vim.tbl_keys(styles);
	table.sort(keys);

	--- Iterate over keys and get the first
	--- match.
	for _, key in ipairs(keys) do
		if key == "default" then goto continue; end
		local entry = styles[key] or {};
		local can_validate, valid = pcall(entry.condition, msg, lines, extmarks);

		if can_validate and valid ~= false then
			_output = vim.tbl_extend("force", _output, entry);
			break;
		end

	    ::continue::
	end

	---@type ui.message.list__static
	local output = {};

	--- Turn dynamic values into static
	--- values
	for k, v in pairs(_output) do
		if type(v) ~= "function" then
			output[k] = v;
		elseif k ~= "condition" then
			local can_run, val = pcall(v, msg, lines, extmarks);

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

--- Gets the message processor for `msg`.
---@param msg ui.message.entry
---@param lines string[]
---@param extmarks ui.message.extmarks
---@return ui.message.style__static
spec.get_msg_style = function (msg, lines, extmarks)
	---|fS

	local processors= spec.config.message.msg_styles or {};
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

--- Is `msg` a list type message?
---@param kind ui.message.kind
---@param content ui.message.fragment[]
---@return boolean
spec.is_list = function (kind, content)
	---|fS

	if not spec.config.message.is_list then
		return false;
	end

	local can_cond, cond = pcall(spec.config.message.is_list, kind, content);
	return can_cond and cond;

	---|fE
end

--- Gets popup menu item style.
---@param word string
---@param kind ui.popupmenu.kind
---@param menu string
---@param info string
---@return ui.popupmenu.style__static
spec.get_item_config = function (word, kind, menu, info)
	---|fS

	local styles = spec.default.popupmenu.entries or {};
	---@type ui.popupmenu.style
	local _output = styles.default or {};

	---@type string[]
	local keys = vim.tbl_keys(styles);
	table.sort(keys);

	--- Iterate over keys and get the first
	--- match.
	for _, key in ipairs(keys) do
		if key == "default" then goto continue; end
		local entry = styles[key] or {};
		local can_validate, valid = pcall(entry.condition, word, kind, menu, info);

		if can_validate and valid ~= false then
			_output = vim.tbl_extend("force", _output, entry);
			break;
		end

	    ::continue::
	end

	---@type ui.popupmenu.style__static
	local output = {};

	--- Turn dynamic values into static
	--- values
	for k, v in pairs(_output) do
		if type(v) ~= "function" then
			output[k] = v;
		elseif k ~= "condition" then
			local can_run, val = pcall(v, word, kind, menu, info);

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

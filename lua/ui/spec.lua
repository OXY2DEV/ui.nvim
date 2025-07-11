local spec = {};
local utils = require("ui.utils");

--- Creates message text from highlight group properties.
---@param props table
---@return string[]
---@return ( ui.message.hl_fragment[] )[]
local function hl_prop_txt (props)
	---|fS

	local lines, exts = {}, {};

	local function new_property (name, value, hl)
		table.insert(lines, string.format("  %s: %s", name, value));
		table.insert(exts, {});

		table.insert(exts[#exts], { 2, 2 + #name, "@property" });
		table.insert(exts[#exts], { 2 + #name, 2 + #name + 1, "@punctuation" });

		table.insert(exts[#exts], { 2 + #name + 2, 2 + #name + 2 + #value, hl or "@string.special" });
	end

	table.insert(lines, string.format("Name: %s", props.group_name));
	table.insert(exts, {});

	table.insert(exts[#exts], { 0, 5, "@property" });
	table.insert(exts[#exts], { 6, 6 + #props.group_name, "@string" });

	if props.value then
		if props.value.link then
			new_property("link", tostring(props.value.link), tostring(props.value.link));
		end

		if vim.islist(props.value.cterm) then
			table.insert(lines, "  cterm:");
			table.insert(exts, {});

			table.insert(exts[#exts], { 2, 7, "@property" });
			table.insert(exts[#exts], { 7, 8, "@punctuation" });

			for _, item in ipairs(props.value.cterm) do
				table.insert(lines, string.format("    • %s", tostring(item)));
				table.insert(exts, {});

				table.insert(exts[#exts], { 4, 4 + #"•", "@punctuation" });
				table.insert(exts[#exts], { #"    • ", #lines[#lines], "@constant" })
			end
		end

		if props.value.start then
			new_property("start", tostring(props.value.start), "@string.special");
		end

		if props.value.stop then
			new_property("stop", tostring(props.value.stop), "@string.special");
		end

		if props.value.ctermfg then
			new_property("ctermfg", tostring(props.value.ctermfg), "@number");
		end

		if props.value.ctermbg then
			new_property("ctermbg", tostring(props.value.ctermbg), "@number");
		end

		if vim.islist(props.value.gui) then
			table.insert(lines, "gui:");
			table.insert(exts, {});

			table.insert(exts[#exts], { 0, 3, "@property" });
			table.insert(exts[#exts], { 3, 4, "@punctuation" });

			for _, item in ipairs(props.value.gui) do
				table.insert(lines, string.format("  • %s", tostring(item)));
				table.insert(exts, {});

				table.insert(exts[#exts], { 2, 2 + #"•", "@punctuation" });
				table.insert(exts[#exts], { #"  • ", #lines[#lines], "@constant" })
			end
		end

		if props.value.font then
			new_property("font", props.value.font, "@string");
		end

		if props.value.guifg then
			new_property("guifg", props.value.guifg, "@constant");
		end

		if props.value.guibg then
			new_property("guibg", props.value.guibg, "@constant");
		end

		if props.value.guisp then
			new_property("guisp", props.value.guisp, "@constant");
		end

		if props.value.blend then
			new_property("blend", props.value.blend, "@number");
		end
	end

	return lines, exts;

	---|fE
end

--- Checks if a message is a list message.
---@param lines string[]
---@return boolean
spec.generic_list_msg = function (lines)
	---|fS

	local start_marker = "";

	for _, line in ipairs(lines) do
		if string.match(line, "%w") then
			start_marker = line;
			break;
		end
	end

	local match_patterns = {
		-- Output of `:ls`, `:ls!`, `:files`, `:buffers`
		--   1 #a   "[No Name]"                    line 1
		'%d+ [u%%#ah%-=RF%?%+x ]- "[^"]+" +line %d+',

		-- Output of `:marks`
		-- mark line  col file/text
		"mark +line +col +file/text",

		-- Output of `:jumps`
		-- jump line  col file/text
		"jump +line +col +file/text",

		-- Output of `:changes`
		-- change line  col text
		"change +line +col +text",

		-- Output of `:undolist`
		-- number changes  when               saved
		"number +changes +when +saved",

		-- Output of `:reg`
		-- Type Name Content
		"Type +Name +Content",

		-- Output of `:map` & `:ab`
		-- n  &           * :&&<CR>
		"[nvxsoilct] +%S+ +%* *.+",

		-- Output of `:history`
		-- n  &           * :&&<CR>
		"# +cmd history",
		"# +search history",
		"# +expr history",
		"# +input history",
		"# +debug history",

		-- Output of `:hi`
		-- SpecialKey     xxx guifg=NvimDarkGrey4
		"%S+ +xxx +.+",

		-- Output of `:tags`
		--  # TO tag         FROM line  in file/text
		"# +TO +tag +FROM +line +in +file/text",

		-- Output of `:clist` & `:llist`
		--  1 main.c:17 col 20-23 warning: Result of integer division used in a floating point context; possible loss of precision↩
		-- 1 main.c:12 col 9: int ROW, COL;↩
		"%d+ .-:[%d-]+ col [%d-]+ %w+: .+",

		-- Output of `:scriptnames`
		-- 1: /path/to/script.vim
		"%d+: .-%.vim$",
		"%d+: .-%.lua$",

		-- Output of `:command`
		-- Name              Args Address Complete    Definition
		"Name +Args +Address +Complete +Definition",

		-- Output of `:au`
		"%-%-%- Autocommands %-%-%-",

		-- Output of `:grep`
		-- This gets in the way for now.
		-- "[^:+]:%d+:%d+:.-"
	};

	local additional_condition = {
		[9] = function (_lines)
			if #_lines <= 2 then
				return false;
			end

			return true;
		end
	};

	for p, pattern in ipairs(match_patterns) do
		if string.match(start_marker, pattern) then
			if additional_condition[p] then
				local ran_cond, cond = pcall(additional_condition[p], lines);

				if ran_cond and cond then
					return true;
				end
			else
				return true;
			end
		end
	end

	return false;

	---|fE
end

--- Checks if a message is a list message is valid.
---@param lines string[]
---@return boolean
spec.ignore_list = function (lines)
	---|fS

	local _lines = utils.trim_lines(lines);

	if string.match(_lines[1] or "", "%S+ +xxx +.+") and #_lines == 1 then
		-- Ignore output of `:hi <group>`
		return true;
	elseif string.match(_lines[1] or "", "^no%w+$") and #_lines == 1 then
		-- Ignore output of `set no<option>?`
		return true;
	elseif string.match(_lines[1] or "", "^.-=.-$") and #_lines == 1 then
		-- Ignore output of `set <option>?`
		return true;
	elseif #lines == 1 then
		-- List messages can't be 1 liners.
		return true;
	end

	return false;

	---|fE
end

---@type ui.config
spec.default = {
	popupmenu = {
		---|fS

		enable = true,

		winconfig = function (_, position)
			---|fS

			if position == "top_left" then
				return {
					border = {
						{ "╭", "@comment" },
						{ "─", "@comment" },
						{ "╮", "@comment" },
						{ "│", "@comment" },
						{ "╯", "@comment" },
						{ "─", "@comment" },
						{ "├", "@comment" },
						{ "│", "@comment" },
					},
				};
			elseif position == "top_right" then
				return {
					border = {
						{ "╭", "@comment" },
						{ "─", "@comment" },
						{ "╮", "@comment" },
						{ "│", "@comment" },
						{ "╯", "@comment" },
						{ "─", "@comment" },
						{ "├", "@comment" },
						{ "│", "@comment" },
					},
				};
			elseif position == "bottom_left" then
				return {
					border = {
						{ "╭", "@comment" },
						{ "─", "@comment" },
						{ "┤", "@comment" },
						{ "│", "@comment" },
						{ "╯", "@comment" },
						{ "─", "@comment" },
						{ "╰", "@comment" },
						{ "│", "@comment" },
					},
				};
			elseif position == "bottom_right" then
				return {
					border = {
						{ "├", "@comment" },
						{ "─", "@comment" },
						{ "╮", "@comment" },
						{ "│", "@comment" },
						{ "╯", "@comment" },
						{ "─", "@comment" },
						{ "╰", "@comment" },
						{ "│", "@comment" },
					},
				};
			end

			return { border = "none" };

			---|fE
		end,
		tooltip = function ()
			local mode = vim.api.nvim_get_mode().mode;
			return mode == "c" and {
				{ " 󰸾 󰹀 ", "UIMenuKeymap" },
			} or {
				{ " 󰹁 󰸽 ", "@comment" },
			};
		end,

		styles = {
			---|fS

			default = {
				padding_left = " ",
				padding_right = " ",

				icon = "󰘎 ",
				icon_hl = "Special",

				select_hl = "UIMenuSelect"
			},

			-- Buffer variables(b:).
			buffer_variable = {
				condition = function (word)
					return string.match(word, "^b:") ~= nil;
				end,

				icon = "󱂕 ",
				icon_hl = "@constant",
			},

			-- Global variables(g:).
			global_variable = {
				condition = function (word)
					return string.match(word, "^g:") ~= nil;
				end,

				icon = " ",
				icon_hl = "@constant",
			},

			-- Local/argument variables(l:,a:,s:).
			local_variable = {
				condition = function (word)
					return string.match(word, "^[las]:") ~= nil;
				end,

				icon = " ",
				icon_hl = "@constant",
			},

			-- Tab variables(t:).
			tabpage_variable = {
				condition = function (word)
					return string.match(word, "^t:") ~= nil;
				end,

				icon = "󰓩 ",
				icon_hl = "@constant",
			},

			-- Vim variables(v:).
			vim_variable = {
				condition = function (word)
					return string.match(word, "^v:") ~= nil;
				end,

				icon = " ",
				icon_hl = "@constant",
			},

			-- Window variables(w:).
			window_variable = {
				condition = function (word)
					return string.match(word, "^w:") ~= nil;
				end,

				icon = " ",
				icon_hl = "@constant",
			},


			class = {
				condition = function (_, kind)
					return kind == "m";
				end,

				icon = " "
			},

			["function"] = {
				condition = function (word, kind)
					return kind == "f" or string.match(word, "%(%)?$") ~= nil;
				end,

				icon = "󰡱 ",
				icon_hl = "@function",
			},

			macro = {
				condition = function (_, kind)
					return kind == "d";
				end,

				icon = "󰕠 ",
				icon_hl = "Macro"
			},

			type_definiton = {
				condition = function (_, kind)
					return kind == "t";
				end,

				icon = " ",
				icon_hl = "Typedef",
			},

			variable = {
				condition = function (_, kind)
					return kind == "v";
				end,

				icon = "󰏖 ",
				icon_hl = "@constant",
			},

			---|fE
		}

		---|fE
	},

	cmdline = {
		---|fS

		enable = true,

		row_offset = 1,

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
				filetype ="cmdline_search",

				icon = { { "  ", "UICmdlineSearchUpIcon" } },

				---|fE
			},

			search_down = {
				---|fS

				condition = function (state)
					return state.firstc == "?";
				end,

				winhl = "Normal:UICmdlineSearchDown",
				filetype ="cmdline_search",

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
					---@type string? Shell name.
					local shell = string.match(vim.o.shell, "%w+$");

					if state.pos < 1 then
						return "vim";
					elseif shell then
						return shell;
					else
						return "bash";
					end
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

			-- Used for prompt keys,
			-- E.g. [O]pen, (E)dit, (Q)uit
			__keymap = {
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

			prompt = {
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

						table.insert(_line, { line, "@comment" })
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
		wrap_notify = true,
		respect_replace_last = true,

		history_preference = "vim",
		history_types = {
			normal = true,
			hidden = false,
			list = false,
			confirm = false,
		},
		max_lines = nil,
		max_duration = 5000,

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

		showcmd = {
			max_width = math.floor(vim.o.columns * 0.4),

			modifier = function (_, lines)
				---|fS

				local mode = vim.api.nvim_get_mode().mode;
				local text = lines[#lines];

				if string.match(mode, "[vVsS]") then
					-- Visual mode ranges should be handled
					-- differently.
					local line = string.format("󰾂 %s", text);

					return {
						lines = { line },
						extmarks = {
							{
								{ 0, #line, "@constant" }
							}
						}
					};
				elseif string.match(text, "^%d*q") then
					-- Macro recording.
					local line = string.format("󰻂 %s", text);

					return {
						lines = { line },
						extmarks = {
							{
								{ 0, #line, "@constant" }
							}
						}
					};
				elseif string.match(text, "^%d*@") then
					-- Macro playing.
					local line = string.format(" %s", text);

					return {
						lines = { line },
						extmarks = {
							{
								{ 0, #line, "DiagnosticOk" }
							}
						}
					};
				elseif string.match(text, "^%d+$") then
					-- Count.
					local line = string.format(" %s", text);

					return {
						lines = { line },
						extmarks = {
							{
								{ 0, #line, "DiagnosticWarn" }
							}
						}
					};
				end

				local line = string.format("󰌏 %s", text);

				return {
					lines = { line },
					extmarks = {
						{
							{ 0, #line, "@function" }
						}
					}
				};

				---|fE
			end
		},

		msg_styles = {
			---|fS

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

					if not msg.content then
						return config;
					end

					local content = msg.content[1];
					local hl = utils.attr_to_hl(content[3]);

					if #msg.content == 1 then
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
					elseif string.match(content[2] or "", " .+ %w+%.nvim ") or string.match(content[2] or "", " %w+%.%w+ ") then
						-- Error message format used by my plugins & blink.cmp
						-- e plugin.nvim : Some message. 
						return {};
					end

					return config;
				end,

				---|fE
			},

			__swap = {
				---|fS

				condition = function (_, lines)
					return string.match(lines[2], "Found a swap file") ~= nil;
				end,

				decorations = {
					icon = {
						{ "▍ ", "UIMessageWarnSign" }
					},
					padding = {
						{ "▍  ", "UIMessageWarnSign" }
					},
					line_hl_group = "UIMessageWarn",
				}

				---|fE
			},

			__spell = {
				---|fS

				condition = function (_, lines)
					return string.match(lines[1], "Word (.+) added to .-%.add$") ~= nil;
				end,

				decorations = {
					icon = {
						{ "▍ ", "UIMessageOk" }
					},
					padding = {
						{ "▍  ", "UIMessageOk" }
					},
				}

				---|fE
			},

			__lua_error = {
				---|fS

				condition = function (_, lines)
					for _, line in ipairs(lines) do
						if string.match(line, ".-Error.-:%d+: ?.-$") then
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
						if string.match(_line, "Error executing (.+):%d") then
							exec = string.match(_line, "Error executing (.+):%d");

							if string.match(exec, "lua (.+)$") then
								exec = "lua " .. utils.path(
									string.match(exec, "lua (.+)$")
								);
							end
						end

						if string.match(_line, ".-:%d+: ?.-$") then
							path, line, actual_error = string.match(_line, "(.-):(%d+): ?(.-)$");

							if string.match(path, "%[.-%]$") then
								path = string.match(path, "%[.-%]$");
							else
								path = utils.path(
									string.match(path, "%S+$")
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

			option = {
				---|fS

				condition = function (_, lines)
					if string.match(lines[1], "^%s+%w+=") then
						local opt, val = string.match(lines[1], "^%s+(%w+)=(.*)$");

						if vim.o[opt] == nil then
							return false;
						elseif type(vim.o[opt]) ~= utils.get_type(val) then
							return false;
						end

						return true;
					end

					local option = string.match(lines[1], "^%s*(%w%w+)$");

					if not option then
						return false;
					end

					option = string.gsub(option, "^no", "");
					return vim.o[option] ~= nil and type(vim.o[option]) == "boolean";
				end,

				modifier = function (_, lines)
					if string.match(lines[1], "^%s*(%w+)$") then
						local key = string.match(lines[1], "^%s*(.*)$");
						local state = string.match(key, "^no") == nil;

						key = string.gsub(key, "^no", "");

						return {
							lines = {
								string.format("%s: %s", key, tostring(state))
							},
							extmarks = {
								{
									{ 0, #key, "@property" },
									{ #key, #key + 1, "@punctuation" },
									{ #key + 2, #key + 2 + #tostring(state), "@boolean" },
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

			error_msg = {
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
					local is_hl, data = utils.is_hl_line(lines[2] or "")
					return lines[1] == "" and is_hl and data.value.link;
				end,

				modifier = function (_, lines)
					local _, data = utils.is_hl_line(lines[2] or "")

					local definition = vim.api.nvim_exec2("hi " .. data.value.link, { output = true }).output;
					local _, def_data = utils.is_hl_line(definition);

					local d_lines, d_exts = hl_prop_txt(def_data);

					-- Remove the group name part.
					table.remove(d_lines, 1);
					table.remove(d_exts, 1);

					local o_lines, o_exts = {
						"abcABC 123",
						"Name: " .. data.group_name,
						"  link: " .. data.value.link,
						"",
						"Raw definition:"
					}, {
						{
							{ 0, 10, data.group_name }
						},
						{
							{ 0, 4, "@property" },
							{ 4, 5, "@punctuation" },
							{ 6, 6 + #data.group_name, "@string" },
						},
						{
							{ 0, 6, "@property" },
							{ 6, 7, "@punctuation" },
							{ 8, 8 + #data.value.link, "@constant" },
						},
						{},
						{
							{ 0, #"Raw definition", "DiagnosticHint" },
							{ #"Raw definition", #"Raw definition" + 1, "@punctuation" },
						},
					};

					o_lines = vim.list_extend(o_lines, d_lines);
					o_exts = vim.list_extend(o_exts, d_exts);

					return {
						lines = o_lines,
						extmarks = o_exts
					};
				end,
				decorations = {
					icon = {
						{ "▍ ", "UIMessagePalette" }
					},
					padding = {
						{ "▍  ", "UIMessagePalette" }
					},
				},

				---|fE
			},

			highlight_group = {
				---|fS

				condition = function (_, lines)
					local is_hl, data = utils.is_hl_line(lines[2] or "")
					return lines[1] == "" and is_hl and data.value.link == nil;
				end,

				modifier = function (_, lines)
					local _, data = utils.is_hl_line(lines[2] or "")
					local d_lines, d_exts = hl_prop_txt(data);

					local o_lines, o_exts = {
						"abcABC 123",
					}, {
						{
							{ 0, 10, data.group_name }
						},
					};

					o_lines = vim.list_extend(o_lines, d_lines);
					o_exts = vim.list_extend(o_exts, d_exts);

					return {
						lines = o_lines,
						extmarks = o_exts
					};
				end,

				decorations = {
					icon = {
						{ "▍ ", "UIMessagePalette" }
					},
					padding = {
						{ "▍  ", "UIMessagePalette" }
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
			},

			undo_redo = {
				---|fS

				condition = function (_, lines)
					if lines[1] == "Already at oldest change" then
						return true;
					elseif lines[1] == "Already at newest change" then
						return true;
					end

					return string.match(lines[1], "%d+ .-; %w+ #%d+") ~= nil or  string.match(lines[1], "%d+ line less; %w+ #%d+") ~= nil;
				end,

				decorations = {
					icon = {
						{ "󰫇 ", "DiagnosticInfo" }
					},
					padding = {
						{ "  ", "DiagnosticInfo" }
					},

					line_hl_group = "@comment"
				}

				---|fE
			},


			terminal_command = {
				---|fS

				condition = function (_, lines)
					return string.match(lines[1] or "", "^:!") ~= nil
				end,

				modifier = function (_, lines)
					---@type string Removed trailing `^M`.
					local removed_tail = string.gsub(lines[1] or "", ".$", "");

					return {
						extmarks = {
							{ {  0, #removed_tail, "UICmdlineEvalIcon" } }
						},
						lines = { removed_tail }
					};
				end,

				decorations = {
					icon = {
						{ "▍ ", "UICmdlineEvalIcon" }
					},
					padding = {
						{ "▍  ", "UICmdlineEvalIcon" }
					},

					line_hl_group = "UICmdlineEval"
				}

				---|fE
			},

			shell_output = {
				---|fS

				condition = function (entry)
					return entry.kind == "shell_out";
				end,

				decorations = {
					icon = {
						{ "▍󰡠 ", "UICmdlineSubstituteIcon" }
					},
					padding = {
						{ "▍", "UICmdlineSubstituteIcon" }
					},

					line_hl_group = "UICmdlineSubstitute"
				}

				---|fE
			},

			---|fE
		},

		is_list = function (kind, content, add_to_history)
			local lines = utils.to_lines(content);

			if kind == "list_cmd" then
				if spec.ignore_list(lines) == true then
					-- Ignore certain messages that
					-- look like lists but aren't in reality.
					return false, true;
				else
					return true, add_to_history;
				end
			end

			return spec.generic_list_msg(lines), false;
		end,

		list_styles = {
			default = {},

			ls = {
				---|fS

				condition = function (msg, lines)
					if msg.kind ~= "list_cmd" then
						return false;
					elseif string.match(lines[2], '^%s*(%d+)%s*([u%%#ah%-=RF%?%+x]+)%s*"(.+)"%s*line (%d+)$') == nil then
						return false;
					end

					return true;
				end,

				modifier = function (_, lines)
					local _lines, exts = {}, {};
					local entries = {};

					---@type table<string, integer>
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
							"UILSBuffer"
						},
						{
							string.format(" %-" .. widths.name .. "s ", "Name"),
							"UILSBufname"
						},
						{
							string.format(" %-" .. widths.indicators .. "s ", "Indicators"),
							"UILSIndicator"
						},
						{
							string.format(" %-" .. widths.lnum .. "s ", "Line"),
							"UILSLmum"
						},
					});

					table.insert(_lines, title);
					table.insert(exts, title_exts);

					for e, entry in ipairs(entries) do
						local row, row_exts = utils.to_row({
							{
								string.format(" %-" .. widths.id .. "s ", entry.id),
								e % 2 == 0 and "@comment" or "UICmdlineSearchDown"
							},
							{
								string.format(" %-" .. widths.name .. "s ", entry.name),
								e % 2 == 0 and "@comment" or "UICmdlineDefault"
							},
							{
								string.format(" %-" .. widths.indicators .. "s ", entry.indicators),
								e % 2 == 0 and "@comment" or "UICmdlineLua"
							},
							{
								string.format(" %-" .. widths.lnum .. "s ", entry.lnum),
								e % 2 == 0 and "@comment" or "UICmdlineSubstitute"
							},
						});

						table.insert(_lines, row);
						table.insert(exts, row_exts);
					end

					return { lines = _lines, extmarks = exts };
				end,

				winhl = "Normal:@comment",
				-- border = "rounded"

				---|fE
			},

			hi = {
				---|fS

				condition = function (_, lines)
					local is_hl = utils.is_hl_line(lines[2] or "");
					require("ui.log").print(is_hl, "Blah");
					return lines[1] == "" and is_hl;
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
					lines = {
						" 󰾴 Swap file detected! ",
						"      See  :swap "
					},
					extmarks = {
						{
							{ 0, 26, "DiagnosticWarn" }
						},
						{
							{ 6, 10, "@comment" },
							{ 10, 17, "DiagnosticVirtualTextHint" }
						}
					}
				},

				border = "rounded",
				winhl = "FloatBorder:DiagnosticWarn,Normal:Normal"

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
								{ 0, 13, "@comment" },
								{ 13, 15 + #file, "DiagnosticVirtualTextHint" },
								{ 15 + #file, 16 + #file, "@comment" },
							}
						}
					};
				end,

				border = "rounded",

				---|fE
			},
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
---@param history boolean
---@return boolean
---@return boolean
spec.is_list = function (kind, content, history)
	---|fS

	if not spec.config.message.is_list then
		return false, false;
	end

	local ran_cond, cond, save = pcall(spec.config.message.is_list, kind, content, history);

	if ran_cond then
		return cond, save;
	else
		return false, false;
	end

	---|fE
end

--- Gets popup menu item style.
---@param word string
---@param kind ui.popupmenu.kind
---@param menu string
---@param info string
---@return ui.popupmenu.style__static
spec.get_item_style = function (word, kind, menu, info)
	---|fS

	local styles = spec.default.popupmenu.styles or {};
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

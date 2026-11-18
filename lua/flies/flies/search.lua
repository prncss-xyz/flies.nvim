---@class Search: _Fly
local M = require("flies.flies._fly"):new {}

M.solid = true

function M:select(opts)
	require("flies")._params = {
		opts = opts,
		target = self,
	}
	if opts.axis == "hint" then
		require("flies.utils.hint").hint(M.get_search_targets(), function(pos)
			require("flies.utils.windows").set_cursor(pos)
			vim.cmd "normal! gn"
		end)
	elseif
		opts.axis == "best"
		or opts.axis == "upward"
		or opts.axis == "forward"
	then
		vim.cmd "normal! gn"
	elseif opts.axis == "backward" then
		vim.cmd "normal! gN"
	end
end

function M:move(opts)
	require("flies")._params = {
		opts = opts,
		target = self,
	}
	if opts.axis == "hint" then
	elseif
		opts.axis == "best"
		or opts.axis == "upward"
		or opts.axis == "forward"
	then
		M.search(true)
	elseif opts.axis == "backward" then
		M.search(false)
	end
end

local search_forward

local function search_n(forward)
	if forward == search_forward then
		vim.cmd "normal! n"
	else
		vim.cmd "normal! N"
	end
	if require("flies").config.hlslens then require("hlslens").start() end
end

function M.set_search(fwd)
	local move_again = require "flies.actions.move_again"
	search_forward = fwd
	move_again.register(
		function() search_n(false) end,
		function() search_n(true) end
	)
end

--- matches of last search pattern in visible lines
---@return {s: integer[], match: integer[]}[]
function M.get_search_targets()
	local pattern = vim.fn.getreg("/", nil, nil) --[[@as string]]
	if pattern == "" then return {} end
	if vim.o.ignorecase and not (vim.o.smartcase and pattern:find "%u") then
		pattern = "\\c" .. pattern
	end
	local regex = vim.regex(pattern)
	local top_line, bot_line = vim.fn.line "w0", vim.fn.line "w$"
	local targets = {}
	local row = top_line
	while row <= bot_line do
		local fold_end = vim.fn.foldclosedend(row)
		if fold_end ~= -1 then
			row = fold_end + 1
		else
			local line = vim.fn.getline(row)
			local offset = 0
			while offset <= #line do
				local s, e = regex:match_str(line:sub(offset + 1))
				if not s then break end
				local pos = { row, offset + s + 1 }
				table.insert(targets, { s = pos, match = pos })
				offset = offset + math.max(e, s + 1)
			end
			row = row + 1
		end
	end
	return targets
end

function M.search(fwd)
	local editor = require "flies.utils.editor"
	M.set_search(fwd)
	vim.api.nvim_feedkeys(editor.t(fwd and "/" or "?"), "n", false)
end

return M

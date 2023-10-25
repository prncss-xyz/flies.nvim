---buffers operation
---the aim of this module is to wrap different buffer operations
---to provide operations normalized to (1, 1) coordinates

---@alias wiseness "v"|"V"
---@alias mode "n"|"o"|"x"

local lists = require "flies.utils.lists"
local utils = require "flies.utils"
local windows = require "flies.utils.windows"

local M = {}

--- feeds given key sequence (interprenting escaped values), noremap
---@param str string
local function feedkeys(str)
	local k = vim.api.nvim_replace_termcodes(str, true, true, true)
	vim.api.nvim_feedkeys(k, "n", true)
end

--- wrapper function used to get visual selection range
---@param cb fun(): nil
function M.with_x(cb)
	feedkeys "<esc>"
	vim.defer_fn(function() cb() end, 0)
end

--- get current mode
---@return mode
function M.get_mode()
	local mode = vim.api.nvim_get_mode().mode
	if mode:match "[o]" then
		return "o"
	elseif mode:match "[vV]" then
		return "x"
	else
		return "n"
	end
end

-- see also https://github.com/echasnovski/mini.nvim/blob/main/lua/mini/surround.lua
--- get marks and wiseness for relevant mode
---@param bufnr integer
---@param mode mode
---@return integer[], integer[], wiseness
function M.get_marks(bufnr, mode)
	-- Region is inclusive on both ends
	local mark1, mark2
	if mode == "x" then
		mark1, mark2 = "<", ">"
	else
		mark1, mark2 = "[", "]"
	end
	local pos1 = vim.api.nvim_buf_get_mark(bufnr, mark1)
	local pos2 = vim.api.nvim_buf_get_mark(bufnr, mark2)
	local wiseness = vim.fn.visualmode()
	wiseness = wiseness == "V" and "V" or "v"
	if wiseness == "v" then
		pos1[2], pos2[2] = pos1[2] + 1, pos2[2] + 1
	else
		local line = M.get_line(bufnr, pos2[1])
		pos1[2] = 1
		pos2[2] = math.max(1, line:len())
	end

	return pos1, pos2, wiseness
end

--- gets last line of buffer
---@param bufnr integer buffer handle or 0 for current
---@return integer
function M.get_eob(bufnr) return vim.api.nvim_buf_line_count(bufnr) end

--- gets line's contents
---@param bufnr integer buffer's number or 0 for current
---@param row integer
---@return string
function M.get_line(bufnr, row)
	return vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]
end

--- returns index of the last char of a line, or 1 if line is empty
---@param line string
--TODO: remove
function M.last_char_index(line)
	local len = line:len()
	if len == 0 then
		return 1
	else
		return len
	end
end

--- iterates over lines of a buffer
---@param bufnr integer
---@param fwd boolean
---@param row integer
---@param lookahead integer?
---@return fun(): integer?, string?
function M.get_lines(bufnr, fwd, row, lookahead)
	local sgn = fwd and 1 or -1
	local ext
	if fwd then
		ext = M.get_eob(bufnr)
		if lookahead then ext = math.min(ext, row + lookahead - 1) end
		ext = ext + 1
	else
		if row == utils.infinity then row = M.get_eob(bufnr) end
		ext = 1
		if lookahead then ext = math.max(ext, row - lookahead + 1) end
		ext = ext - 1
	end
	row = row - sgn
	return function()
		row = row + sgn
		if row == ext then return end
		return row, vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]
	end
end

--- gets range's contents
---@param bufnr integer Buffer handle, 0 for current buffer
---@param range integer[][]
---@return string
function M.get_range(bufnr, range)
	return table.concat(
		vim.api.nvim_buf_get_text(
			bufnr,
			range[1][1] - 1,
			range[1][2] - 1,
			range[2][1] - 1,
			range[2][2],
			{}
		),
		"\n"
	)
end

function M.get_contents(bufnr, range)
	return vim.api.nvim_buf_get_text(
		bufnr,
		range[1][1] - 1,
		range[1][2] - 1,
		range[2][1] - 1,
		range[2][2],
		{}
	)
end

local function to_lsp_range(range)
	local s, e = unpack(range)
	local start
	if vim.deep_equal(s, {}) then
		start = { line = e[1] - 1, character = e[2] }
	else
		start = { line = s[1] - 1, character = s[2] - 1 }
	end
	local end_
	if vim.deep_equal(e, {}) then
		end_ = { line = s[1] - 1, character = s[2] - 1 }
	else
		end_ = { line = e[1] - 1, character = e[2] }
	end
	return { start = start, ["end"] = end_ }
end

local function get_lsp_edit(edit)
	local range, new_text = unpack(edit)
	return { range = to_lsp_range(range), newText = new_text }
end

---concurently apply edits operations to a buffer
---(this means you don't have to worry about how an operation changes the coordonates needed to perform the next one)
---@param bufnr integer buffer's number or 0 for current
---@param edits table a list of triplets {start, end_, new_text}
function M.edit(bufnr, edits)
	vim.lsp.util.apply_text_edits(vim.tbl_map(get_lsp_edit, edits), bufnr, "utf-8")
end

--- get the first non-blank character, or first character if line is blank
---@param line string
function M.get_bol(line) return (line:find "%S") or 1 end

--- get the last non-blank character, or last character if line is blank
---@param line string
function M.get_eol(line) return (line:find "%S%s*$") or math.max(1, line:len()) end

function M.prev_blank(bufnr, pos, wiseness)
	local row, col = unpack(pos)
	if wiseness == "v" then
		if col == 1 then
			row = row - 1
			col = math.max(1, M.get_line(bufnr, row):len())
		else
			col = col - 1
		end
	else
		col = math.max(1, M.get_line(bufnr, row):len())
	end
	return { row, col }
end

--- previous char or previous line position
---@param bufnr integer
---@param pos integer[]
---@param wiseness wiseness
---@return integer[]
function M.prev(bufnr, pos, wiseness, blank)
	local row, col = unpack(pos)
	if
		wiseness == "V"
		or row > M.get_eob(bufnr)
		or M.get_line(bufnr, row):sub(1, col - 1):match "^%s*$"
	then
		if row == 1 then return { 1, 1 } end
		row = row - 1
		local len = math.max(1, M.get_line(bufnr, row):len())
		return { row, len }
	end
	return { row, col - 1 }
end

--- next char or next line position
---@param bufnr integer
---@param pos integer[]
---@param wiseness wiseness
---@return integer[]
function M.next(bufnr, pos, wiseness)
	local row, col = unpack(pos)
	if wiseness == "v" then
		local line = M.get_line(bufnr, row)
		-- TODO: check if we need max(1, line:len())
		if col < line:len() then return { row, col + 1 } end
		if row == M.get_eob(bufnr) then return { row, col } end
		row = row + 1
		line = M.get_line(bufnr, row)
		if line == "" then return { row, 1 } end
		col = M.get_bol(line)
		return { row, col }
	end
	return { row + 1, 1 }
end

function M.swap(bufnr, range_a, range_b)
	M.edit(
		bufnr,
		{ { range_a, M.get_range(0, range_b) }, { range_b, M.get_range(0, range_a) } }
	)
end

---substitute surrouding
---@param bufnr integer
---@param inner table
---@param outer table
---@param left_text string
---@param right_text string
function M.substitute(bufnr, inner, outer, left_text, right_text)
	local edits = {}
	left_text = left_text or ""
	right_text = right_text or ""
	if inner[2][2] == M.get_line(0, inner[2][1]):len() then
		right_text = right_text .. "\n"
	else
		table.insert(edits, { { M.next(bufnr, inner[2], "v"), outer[2] }, "" })
	end
	table.insert(edits, { { outer[1], M.prev(bufnr, inner[1], "v") }, left_text })
	table.insert(edits, { { M.next(bufnr, inner[2], "v"), inner[2] }, right_text })

	-- TODO: what about tabs?
	local tab = vim.api.nvim_buf_get_option(bufnr, "shiftwidth")
	--TODO: is there a lsp_edit way to get to last char of a line
	for row = inner[1][1] + 1, inner[2][1] do
		table.insert(edits, { { { row, 1 }, { row, tab } }, "" })
	end
	M.edit(bufnr, edits)
end

--- get wiseness for given range
---@param bufnr integer
---@param range integer[][]
---@param lonely_wiseness wiseness
---@return wiseness
function M.get_wiseness(bufnr, range, lonely_wiseness)
	local s, e = unpack(range)
	local line = M.get_line(bufnr, s[1])
	local _, col = line:find "^%s*"
	if s[2] > col + 1 then return "v" end
	line = M.get_line(bufnr, e[1])
	col = line:find "%s*$"
	if e[2] < col - 1 then return "v" end
	if s[1] == e[1] then return lonely_wiseness end
	return "V"
end

local function complete(str, wiseness)
	if str == "" then return str end
	if wiseness ~= "V" then return str end
	if vim.endswith(str, "\n") then return str end
	return str .. "\n"
end

function M.subs(bufnr, outer, inner, wiseness, left_text, right_text, tab_text)
	left_text = complete(left_text, wiseness)
	right_text = complete(right_text, wiseness)
	local edits = {}
	if wiseness == "V" then
		table.insert(edits, {
			{ { outer[1][1], 1 }, { inner[1][1], 0 } },
			left_text,
		})
		table.insert(edits, {
			{ { inner[2][1] + 1, 1 }, { outer[2][1] + 1, 0 } },
			right_text,
		})
		local create = not (left_text == "" and right_text == "")
		local del = lists.cmp(outer[1], inner[1]) < 0
			or lists.cmp(inner[2], outer[2]) < 0
		if del and not create then
			for i = inner[1][1], inner[2][1] do
				table.insert(edits, { { { i, 1 }, { i, tab_text:len() } }, "" })
			end
		elseif create and not del then
			for i = inner[1][1], inner[2][1] do
				table.insert(edits, { { { i, 1 }, { i, 0 } }, tab_text })
			end
		end
	else
		table.insert(edits, {
			{ { outer[1][1], outer[1][2] }, { inner[1][1], inner[1][2] - 1 } },
			left_text,
		})
		table.insert(edits, {
			{ { inner[2][1], inner[2][2] + 1 }, { outer[2][1], outer[2][2] } },
			right_text,
		})
	end
	M.edit(bufnr, edits)
end

-- cf. "lua/luasnip/init.lua"
function M.snip_replace(snippet, range, captures)
	local from, to_ = unpack(range)
	require("luasnip").snip_expand(snippet, {
		clear_region = {
			from = { from[1] - 1, from[2] - 1 },
			to = { to_[1] - 1, to_[2] },
		},
		expand_params = { captures = captures },
	})
end

function M.snip_capture(name)
	return require("luasnip").function_node(
		function(_, snip) return snip.captures[name] end,
		{}
	)
end

function M.select2(range, wiseness)
	local s, e = unpack(range)
	windows.set_cursor(s)
	vim.cmd("normal! " .. wiseness)
	windows.set_cursor(e)
end

---@param range string[][]
---@param wiseness wiseness
function M.select(range, wiseness)
	local s, e = unpack(range)
	local cmp = lists.cmp(s, e)
	if cmp <= 0 then
		windows.set_cursor(s)
		vim.cmd("normal! " .. wiseness)
		windows.set_cursor(e)
	elseif cmp > 0 then
		feedkeys "<esc>"
		vim.defer_fn(function() windows.set_cursor(s) end, 0)
	end
end

--- send keys, without remaping. uses <cr>-style representation for non printable characters
---@param str string
function M.feed_keys(str)
	str = vim.api.nvim_replace_termcodes(str, true, true, true)
	vim.api.nvim_feedkeys(str, "n", true)
end

return M

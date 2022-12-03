local M = {}

local function feedkeys(str)
	local k = vim.api.nvim_replace_termcodes(str, true, true, true)
	vim.api.nvim_feedkeys(k, "n", true)
end

function M.with_x(cb)
	feedkeys "<esc>"
	vim.defer_fn(function() cb() end, 0)
end

-- adapted from https://github.com/echasnovski/mini.nvim/blob/main/lua/mini/surround.lua
-- Work with operator marks ---------------------------------------------------
local function get_marks(bufnr, mode)
	-- Region is inclusive on both ends
	local mark1, mark2
	if mode == "x" then
		mark1, mark2 = "<", ">"
	else
		mark1, mark2 = "[", "]"
	end

	local pos1 = vim.api.nvim_buf_get_mark(bufnr, mark1)
	local pos2 = vim.api.nvim_buf_get_mark(bufnr, mark2)

	-- Tweak position in linewise mode as marks are placed on the first column
	local is_linewise = (mode == "line")
		or (mode == "x" and vim.fn.visualmode() == "V")
	if is_linewise then
		-- Move start mark past the indent
		pos1[2] = vim.fn.indent(pos1[1])
		-- Move end mark to the last character (` - 2` here because `col()` returns
		-- column right after the last 1-based column)
		pos2[2] = vim.fn.col { pos2[1], "$" } - 2
	end

	-- Make columns 1-based instead of 0-based. This is needed because
	-- `nvim_buf_get_mark()` returns the first 0-based byte of mark symbol and
	-- all the following operations are done with Lua's 1-based indexing.
	pos1[2], pos2[2] = pos1[2] + 1, pos2[2] + 1

	-- Tweak second position to respect multibyte characters. Reasoning:
	-- - These positions will be used with `region_replace()` to add some text,
	--   which operates on byte columns.
	-- - For the first mark we want the first byte of symbol, then text will be
	--   insert to the left of the mark.
	-- - For the second mark we want last byte of symbol. To add surrounding to
	--   the right, use `pos2[2] + 1`.
	local line2 = vim.fn.getline(pos2[1])
	if mode == "x" and vim.o.selection == "exclusive" then
		-- Respect 'selection' option
		pos2[2] = pos2[2] - 1
	else
		-- Use `math.min()` because it might lead to 'index out of range' error
		-- when mark is positioned at the end of line (that extra space which is
		-- selected when selecting with `v$`)
		local utf_index = vim.str_utfindex(line2, math.min(#line2, pos2[2]))
		-- This returns the last byte inside character because `vim.str_byteindex()`
		-- 'rounds upwards to the end of that sequence'.
		pos2[2] = vim.str_byteindex(line2, utf_index)
	end

	return pos1, pos2
end

function M.get_cursor(winnr)
	local cursor = vim.api.nvim_win_get_cursor(winnr)
	cursor[2] = cursor[2] + 1
	return cursor
end

function M.set_cursor(winnr, cursor)
	local new_cursor = { cursor[1], cursor[2] - 1 }
	vim.api.nvim_win_set_cursor(winnr, new_cursor)
end

function M.get_line(bufnr, row)
	return vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]
end

function M.get_zone(bufnr, s, e)
	return table.concat(
		vim.api.nvim_buf_get_text(bufnr, s[1] - 1, s[2] - 1, e[1] - 1, e[2], {}),
		"\n"
	)
end

local function to_lsp_range(s, e)
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
	local from, to_, new_text = unpack(edit)
	return { range = to_lsp_range(from, to_), newText = new_text }
end

function M.text_replace(bufnr, edits)
	vim.lsp.util.apply_text_edits(vim.tbl_map(get_lsp_edit, edits), bufnr, "utf-8")
end

-- cf. "lua/luasnip/init.lua"
function M.snip_replace(bufnr, snippet, from, to_, expand_params)
	assert(bufnr == 0, "snip_replace can only be used with bufnr=0")
	require("luasnip").snip_expand(snippet, {
		clear_region = {
			from = { from[1] - 1, from[2] - 1 },
			to = { to_[1] - 1, to_[2] },
		},
		expand_params = expand_params,
	})
end

return M

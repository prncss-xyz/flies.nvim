local move_cursor = require("flies.utils").move_cursor
local to_pos = require("flies.utils").to_pos
local line_ending_pos = require("flies.utils").line_ending_pos
local select_line_range = require("flies.utils").select_line_range

-- TODO: previous, next

local function lookahead()
	local max = vim.api.nvim_buf_line_count(0)
	local row = vim.api.nvim_win_get_cursor(0)[1]
	while true do
		local line = vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1]
		if not string.find(line, "^[%s]*$") then
			return row
		end
		row = row + 1
		if row > max then
			return nil
		end
	end
end

local function start(domain, row)
	local indent_base = vim.fn.indent(row)
	local last_row, last_indent = row, indent_base
	local indent = indent_base
	local count = vim.v.count1
	while true do
		if row == 1 then
			return row, indent
		end
		last_row, last_indent = row, indent
		row = row - 1
		indent = vim.fn.indent(row)
		local line = vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1]
		local blank = string.find(line, "^[%s]*$")
		if (domain == "inner" or not blank) and indent < indent_base then
			if count == 1 then
				return last_row, last_indent
			end
			count = count - 1
      indent_base = indent
		end
		if domain == "inner" and blank then
			return last_row, last_indent
		end
	end
end

local function ending(domain, row, indent_base)
	local last_row = row
	local indent = indent_base
	local max = vim.api.nvim_buf_line_count(0)
	while true do
		if row == max then
			return row
		end
		last_row = row
		row = row + 1
		indent = vim.fn.indent(row)
		local line = vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1]
		local blank = string.find(line, "^[%s]*$")
		if (domain == "inner" or not blank) and indent < indent_base then
			return last_row
		end
		if domain == "inner" and blank then
			return last_row
		end
	end
end

local M = require("flies.objects.base").new()

function M.new()
	return setmetatable({}, { __index = M })
end

local function textobject_plain(domain)
	local row = lookahead()
	if not row then
		return
	end
	local row_s, indent = start(domain, row)
	local row_e = ending(domain, row, indent)
	select_line_range(row_s, row_e)
end

function M:textobject_inner_plain(_)
	textobject_plain("inner")
end

function M:textobject_outer_plain(_)
	textobject_plain("outer")
end

return M

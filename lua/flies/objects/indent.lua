local move_cursor = require("flies.utils").move_cursor
local to_pos = require("flies.utils").to_pos
local line_ending_pos = require("flies.utils").line_ending_pos
local select_line_range = require("flies.utils").select_line_range

-- TODO: outer

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
	local indent = vim.fn.indent(row)
	while true do
		local indent0 = vim.fn.indent(row)
		local line = vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1]
		local blank = string.find(line, "^[%s]*$")
		if (domain == "inner" or not blank) and indent0 < indent then
			return row + 1
		end
		if domain == "inner" and blank then
			return row + 1
		end
		if row == 1 then
			return row
		end
		row = row - 1
	end
end

local function ending(domain, row)
	local max = vim.api.nvim_buf_line_count(0)
	local indent = vim.fn.indent(row)
	while true do
		local indent0 = vim.fn.indent(row)
		local line = vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1]
		local blank = string.find(line, "^[%s]*$")
		if (domain == "inner" or not blank) and indent0 < indent then
			return row - 1
		end
		if domain == "inner" and blank then
			return row - 1
		end
		if row == max then
			return row
		end
		row = row + 1
	end
end

local M = require("flies.objects.base").new()

function M.new()
	return setmetatable({}, { __index = M })
end

function M:textobject_inner_plain(_)
	local row = lookahead()
	if not row then
		return
	end
	local row_s = start("inner", row)
	local row_e = ending("inner", row)
	select_line_range(row_s, row_e)
end

function M:textobject_outer_plain(_)
	local row = lookahead()
	if not row then
		return
	end
	local row_s = start("outer", row)
	local row_e = ending("outer", row)
	select_line_range(row_s, row_e)
end

return M

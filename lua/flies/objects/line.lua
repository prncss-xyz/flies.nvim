local name = require("flies.utils").name
local set_selection = require("flies.utils").set_selection
local move_cursor = require("flies.utils").move_cursor
local to_pos = require("flies.utils").to_pos

local function select_line(row, start, ending, wiseness)
	if row then
		set_selection(to_pos(row, start), to_pos(row, ending), wiseness)
	end
end

local function get_row(qualifier)
	local row = vim.api.nvim_win_get_cursor(0)[1]
	if qualifier == "plain" then
		if vim.v.count > 0 then
			row = vim.v.count
		else
			return row
		end
	end
	if qualifier == "previous" then
		row = row - vim.v.count1
		if row < 1 then
			return nil
		end
		return row
	end
	if qualifier == "next" then
		row = row + vim.v.count1
	end
	local max = vim.api.nvim_buf_line_count(0)
	if row > max then
		return nil
	end
	return row
end

local function line_bounds(domain, row)
	local line = vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1]
	if line == "" then
		return 1, 1
	end
	if domain == "inner" then
		local col_s = string.find(line, "[%S]")
		local col_e = string.find(line, ".[%s]*$")
		return col_s, col_e
	end
	if domain == "outer" then
		return 1, line:len()
	end
end

local M = require("flies.objects.base").new()

function M.new()
	return setmetatable({}, { __index = M })
end

for _, domain in ipairs({ "inner", "outer" }) do
	for _, qualifier in ipairs({ "plain", "next", "previous" }) do
		local wiseness = domain == "inner" and "v" or "V"
		M[name("textobject", domain, qualifier)] = function(_, _)
			local row = get_row(qualifier)
			if not row then
				return
			end
			local col_s, col_e = line_bounds(domain, row)
			select_line(row, col_s, col_e, wiseness)
		end
		M[name("move", domain, qualifier)] = function(_, start, _)
			local row = get_row(qualifier)
			if not row then
				return
			end
			local col_s, col_e = line_bounds(domain, row)
			move_cursor(to_pos(row, start and col_s or col_e), wiseness)
		end
	end
end

return M

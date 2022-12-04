local M = require("flies2.utils.objects"):new {}
local buffers = require "flies2.utils.buffers"

M.lonely_wiseness = "v"

function M:get_wiseness(s, e)
	local line = buffers.get_line(0, s[1])
	local _, col = line:find "^%s*"
	if s[2] > col + 1 then return "v" end
	line = buffers.get_line(0, e[1])
	col = line:find "%s*$"
	if e[2] < col - 1 then return "v" end
	if s[1] == e[1] then return self.lonely_wiseness end
	return "V"
end

M.borough_char_pattern = "%s+"
M.borough_line_pattern = "^%s*$"

function M:_post(wiseness, e)
	if wiseness == "v" then
		local line = buffers.get_line(0, e[1]):sub(e[2] + 1)
		local _, e_ = line:find("^" .. self.borough_char_pattern)
		if e_ then
			e_ = e_ + e[2]
			if e_ > e[2] then return { e[1], e_ } end
		end
		return
	else
		local eob = buffers.get_eob(0)
		local row = e[1]
		if row == eob then return end
		local col
		while true do
			local row_ = row + 1
			local line = buffers.get_line(0, row_)
			local _, col_ = line:find(self.borough_line_pattern)
			if not col_ then
				if row then return { row, col } end
				return
			end
			row = row_
			col = col_ == 0 and 1 or col_
			if row == eob then return { row, col } end
		end
	end
end

--- unlike _post, _pre always returns a value, which can be same as `s`
function M:_pre(wiseness, s)
	if wiseness == "v" then
		local line = buffers.get_line(0, s[1]):sub(1, s[2] - 1)
		local _, e_ = line:find(self.borough_char_pattern .. "$", s[2])
		return { s[1], e_ or s[2] }
	else
		local row = s[1]
		local col
		if row == 1 then
			local line = buffers.get_line(0, row)
			local _, col_ = line:find(self.borough_line_pattern)
			local col = col_ == 0 and 1 or col_
			return { row, col }
		end
		while true do
			local row_ = row - 1
			local line = buffers.get_line(0, row_)
			local _, col_ = line:find(self.borough_line_pattern)
			if not col_ then
				if row then return { row, col } end
				return
			end
			row = row_
			col = col_ == 0 and 1 or col_
			if row == 1 then return { row, col } end
		end
	end
end

function M:borough(s, e)
	local wiseness = self:get_wiseness(s, e)
	local e_ = self:_post(wiseness, e)
	if e_ then return s, e_ end
	local s_ = self:_pre(wiseness, s)
	return s_, e
end

return M

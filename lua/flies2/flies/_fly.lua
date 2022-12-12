local M = require("flies2.utils.objects"):new {}
local buffers = require "flies2.utils.buffers"
local iterators = require "flies2.utils.iterators"

M.lonely_wiseness = "v"
M.borough_char_pattern = "%s+"
M.borough_line_pattern = "^%s*$"
M.lookahead = 200

function M:get_wiseness(bufnr, s, e)
	local line = buffers.get_line(bufnr, s[1])
	local _, col = line:find "^%s*"
	if s[2] > col + 1 then return "v" end
	line = buffers.get_line(bufnr, e[1])
	col = line:find "%s*$"
	if e[2] < col - 1 then return "v" end
	if s[1] == e[1] then return self.lonely_wiseness end
	return "V"
end

local function borough_charwise(self, bufnr, s, e)
	local line = buffers.get_line(bufnr, e[1])
	local e_
	-- post
	local line_ = line:sub(e[2] + 1)
	_, e_ = line_:find("^" .. self.borough_char_pattern)
	if e_ then
		e_ = e_ + e[2]
		if e_ > e[2] then return s, { e[1], e_ } end
	end
	-- pre
	line_ = line:sub(1, s[2] - 1)
	_, e_ = line_:find(self.borough_char_pattern .. "$", s[2])
	if e_ then return { s[1], e_ or s[2] }, e end
	return s, e
end

local function borough_post_linewise(self, bufnr, e)
	local eob = buffers.get_eob(bufnr)
	local row, col
	local row_ = e[1]
	if row_ == eob then return end
	while true do
		row_ = row_ + 1
		local line = buffers.get_line(bufnr, row_)
		local _, col_ = line:find(self.borough_line_pattern)
		if not col_ then
			if row then return { row, col } end
			return
		end
		row = row_
		-- `borough_line_pattern` is expected to macth full line
		col = col_ == 0 and 1 or col_
		if row == eob then return { row, col } end
	end
end

local function borough_pre_linewise(self, bufnr, s)
	local row, col
	local row_ = s[1]
	if row_ == 1 then return end
	while true do
		row_ = row_ - 1
		local line = buffers.get_line(bufnr, row_)
		local _, col_ = line:find(self.borough_line_pattern)
		if not col_ then
			if row then return { row, col } end
			return
		end
		row = row_
		-- `borough_line_pattern` is expected to macth full line
		col = col_ == 0 and 1 or col_
		if row == 1 then return { row, col } end
	end
end

function M:borough(bufnr, s, e)
	local wiseness = self:get_wiseness(bufnr, s, e)
	if wiseness == "v" then
		return borough_charwise(self, bufnr, s, e)
	else
		local e_ = borough_post_linewise(self, bufnr, e)
		if e_ then return s, e_ end
		local s_ = borough_pre_linewise(self, bufnr, s)
		if s_ then return s_, e end
		return s, e
	end
end

function M:find_upwards(bufnr, count, pos)
	return iterators.nth(count)(self:iterate_upwards(bufnr, pos))
end

function M:find_backwards(bufnr, count, pos)
	return iterators.nth(count)(self:iterate_backwards(bufnr, pos))
end

function M:find_forwards(bufnr, count, pos)
	return iterators.nth(count)(self:iterate_forwards(bufnr, pos))
end

function M:find_best(bufnr, pos) return self:find_upwards(bufnr, 1, pos) end

return M

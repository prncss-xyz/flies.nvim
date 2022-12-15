local M = require("flies2.utils.objects"):new {}
local buffers = require "flies2.utils.buffers"
local iterators = require "flies2.utils.iterators"
local lists = require "flies2.utils.lists"

M.lonely_wiseness = "v"
M.around_char_pattern = "%s+"
M.around_line_pattern = "^%s*$"
M.lookahead = 200

function M:get_wiseness(bufnr, range)
	local s, e = unpack(range)
	local line = buffers.get_line(bufnr, s[1])
	local _, col = line:find "^%s*"
	if s[2] > col + 1 then return "v" end
	line = buffers.get_line(bufnr, e[1])
	col = line:find "%s*$"
	if e[2] < col - 1 then return "v" end
	if s[1] == e[1] then return self.lonely_wiseness end
	return "V"
end

local function around_charwise(self, bufnr, s, e)
	local line = buffers.get_line(bufnr, e[1])
	local e_
	-- post
	local line_ = line:sub(e[2] + 1)
	_, e_ = line_:find("^" .. self.around_char_pattern)
	if e_ then
		e_ = e_ + e[2]
		if e_ > e[2] then return s, { e[1], e_ } end
	end
	-- pre
	line_ = line:sub(1, s[2] - 1)
	local s_ = line_:find(self.around_char_pattern .. "$")
	if s_ then return { s[1], s_ }, e end
	return s, e
end

local function around_post_linewise(self, bufnr, e)
	local eob = buffers.get_eob(bufnr)
	local row, col
	local row_ = e[1]
	if row_ == eob then return end
	while true do
		row_ = row_ + 1
		local line = buffers.get_line(bufnr, row_)
		local _, col_ = line:find(self.around_line_pattern)
		if not col_ then
			if row then return { row, col } end
			return
		end
		row = row_
		-- `around_line_pattern` is expected to macth full line
		col = col_ == 0 and 1 or col_
		if row == eob then return { row, col } end
	end
end

local function around_pre_linewise(self, bufnr, s)
	local row, col
	local row_ = s[1]
	if row_ == 1 then return end
	while true do
		row_ = row_ - 1
		local line = buffers.get_line(bufnr, row_)
		local _, col_ = line:find(self.around_line_pattern)
		if not col_ then
			if row then return { row, col } end
			return
		end
		row = row_
		-- `around_line_pattern` is expected to macth full line
		col = col_ == 0 and 1 or col_
		if row == 1 then return { row, col } end
	end
end

function M:around(bufnr, range, wiseness)
	local s, e = unpack(range)
	if wiseness == "v" then
		return { around_charwise(self, bufnr, s, e) }
	else
		local e_ = around_post_linewise(self, bufnr, e)
		if e_ then return { s, e_ } end
		local s_ = around_pre_linewise(self, bufnr, s)
		if s_ then return { s_, e } end
		return { s, e }
	end
end

function M:right(bufnr, cursor, inner, wiseness)
	local s, e = unpack(inner)
	local rp = lists.relative_pos(cursor, inner)
	if rp == "backward" then return end
	return { cursor, rp == "upward" and e or buffers.prev(bufnr, s, wiseness) }
end

function M:left(bufnr, cursor, inner, wiseness)
	local s, e = unpack(inner)
	local rp = lists.relative_pos(cursor, inner)
	if rp == "forward" then return end
	return {
		rp == "upward" and s or buffers.next(bufnr, e, wiseness),
		buffers.prev(bufnr, cursor, wiseness),
	}
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

function M:find_best(bufnr, pos)
	return self:find_upwards(bufnr, 1, pos) or self:find_forwards(bufnr, 1, pos)
end

return M

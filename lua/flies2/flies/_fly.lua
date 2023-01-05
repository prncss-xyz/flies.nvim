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

function M:around(bufnr, match, wiseness)
	if match.around then return match.around end
	local s, e = unpack(match.outer)
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

function M:hop_targets_generator(opts, ref)
	local domain = "outer"
	if
		opts.domain == "inner"
		or opts.domain == "left"
		or opts.domain == "right"
	then
		domain = "inner"
	end
	local use_start = opts.domain ~= "right"
	local manh_dist = require("hop.jump_target").manh_dist
	local context = require("hop.window").get_window_context()
	context = context[1].contexts[1]
	local cursor_pos = context.cursor_pos
	local start
	if opts.domain == "right" then
		start = cursor_pos[1]
	else
		start = context.top_line + 1
	end
	local end_
	if opts.domain == "left" then
		end_ = cursor_pos[1] + 1
	else
		end_ = context.bot_line + 1
	end
	local jump_targets = {}
	local indirect_jump_targets = {}
	local index = 0
	-- TODO: stop iterating a line end_
	-- TODO: to be exact, we would need to add objects whose start is outside of screen for opts.domain == "right"
	for to_ in self:iterate_forwards(0, { start, 0 }, ref) do
		if to_[domain][1][1] >= end_ then break end
		local skip = false
		local rel = lists.relative_pos(cursor_pos, to_[domain])
		if opts.domain == "left" and rel == "forward" then skip = true end
		if opts.domain == "right" and rel == "backward" then skip = true end
		if not skip then
			local h = to_[domain][use_start and 1 or 2]
			index = index + 1
			local line = h[1] - 1
			local column = h[2]
			table.insert(jump_targets, {
				line = line,
				column = column,
				window = 0,
				object = to_,
			})
			table.insert(indirect_jump_targets, {
				index = index,
				score = -manh_dist({ line, column }, cursor_pos),
			})
		end
	end
	return {
		jump_targets = jump_targets,
		indirect_jump_targets = indirect_jump_targets,
	}
end

function M:find_upwards(bufnr, count, pos)
	if self.iterate_upwards then
		return iterators.nth(count)(self:iterate_upwards(bufnr, pos))
	end
end

function M:find_backwards(bufnr, count, pos)
	if self.iterate_backwards then
		return iterators.nth(count)(self:iterate_backwards(bufnr, pos))
	end
end

function M:find_forwards(bufnr, count, pos)
	if self.iterate_forwards then
		return iterators.nth(count)(self:iterate_forwards(bufnr, pos))
	end
end

function M:find_best(bufnr, pos)
	return self:find_upwards(bufnr, 1, pos) or self:find_forwards(bufnr, 1, pos)
end

return M

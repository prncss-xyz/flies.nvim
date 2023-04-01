local M = require("flies2.utils.objects"):new {}
local buffers = require "flies2.utils.buffers"
local iterators = require "flies2.utils.iterators"
local lists = require "flies2.utils.lists"

M.lonely_wiseness_inner = "v"
M.lonely_wiseness_outer = "v"
M.around_char_pattern = "%s+"
M.around_line_pattern = "^%s*$"
M.lookahead = 200

function M:get_wiseness(bufnr, range, outer)
	return buffers.get_wiseness(
		bufnr,
		range,
		outer and self.lonely_wiseness_outer or self.lonely_wiseness_inner
	)
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
		if not self.around_char_pattern then return { s, e } end
		return { around_charwise(self, bufnr, s, e) }
	else
		if not self.around_line_pattern then return { s, e } end
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

local function apply_opts(self, opts, pos, match)
	local wiseness
	local range
	if opts.domain == "inner" then
		range = match.inner
		wiseness = self:get_wiseness(0, range, false)
	elseif opts.domain == "left" then
		range = match.inner
		wiseness = self:get_wiseness(0, range)
		range = self:left(0, pos, range, wiseness, false)
	elseif opts.domain == "right" then
		range = match.inner
		wiseness = self:get_wiseness(0, range)
		range = self:right(0, pos, range, wiseness, false)
	elseif opts.domain == "outer" then
		range = match.outer
		wiseness = self:get_wiseness(0, range, true)
		local wants_around
		if opts.around == "always" then
			wants_around = true
		elseif opts.around == "never" then
			wants_around = false
		elseif opts.around == "solid" then
			wants_around = self.solid
		else
			error(string.format("unknown around option: %s", opts.around))
		end
		if wants_around then range = self:around(0, match, wiseness) end
	else
		error(string.format("unknown domain: %s", opts.domain))
	end
	return {
		range = range,
		wiseness = wiseness,
		opts = opts,
		target = self,
		pos = pos,
		match = match,
	}
end

function M:with_opts(opts, cb)
	local pos = buffers.get_cursor()
	local match
	if opts.axis == "best" then
		match = self:find_best(0, pos)
	elseif opts.axis == "upward" then
		match = self:find_upwards(0, opts.count or 1, pos)
	elseif opts.axis == "forward" then
		match = self:find_forwards(0, opts.count or 1, pos)
	elseif opts.axis == "backward" then
		match = self:find_backwards(0, opts.count or 1, pos)
	elseif opts.axis == "hint" then
		require("hop").hint_with_callback(
			function() return self:hop_targets_generator(opts, pos) end,
			require("hop").opts,
			function(res) cb(apply_opts(self, opts, pos, res.object)) end
		)
	else
		error(string.format("unknown axis: %s", opts.axis))
	end
	if not match then return end
	cb(apply_opts(self, opts, pos, match))
end

function M:move(opts)
	self:with_opts(opts, function(params)
		require("flies2")._params = params
		buffers.move(params.range, true)
	end)
end

function M:select(opts)
	self:with_opts(opts, function(params)
		require("flies2")._params = params
		buffers.select(params.range, params.wiseness)
	end)
end

return M

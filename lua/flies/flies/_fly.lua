local M = require("flies.utils.objects"):new {}
local buffers = require "flies.utils.buffers"
local iterators = require "flies.utils.iterators"
local lists = require "flies.utils.lists"

M.lonely_wiseness_inner = "v"
M.lonely_wiseness_outer = "v"
M.around_char_pattern = "%s+"
M.around_line_pattern = "^%s*$"
M.lookahead = 200

function M:get_wiseness(bufnr, match, domain)
	local range = match[domain]
	local lonely_wiseness = domain == "inner" and self.lonely_wiseness_inner
		or self.lonely_wiseness_outer
	return range, buffers.get_wiseness(bufnr, range, lonely_wiseness)
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

function M:around(bufnr, match)
	local outer, wiseness = self:get_wiseness(0, match, "outer")
	if match.around then return match.around, match.around_wiseness or wiseness end
	local s, e = unpack(outer)
	if wiseness == "v" then
		if not self.around_char_pattern then return { s, e }, wiseness end
		return { around_charwise(self, bufnr, s, e) }, wiseness
	else
		if not self.around_line_pattern then return { s, e }, wiseness end
		local e_ = around_post_linewise(self, bufnr, e)
		if e_ then return { s, e_ }, wiseness end
		local s_ = around_pre_linewise(self, bufnr, s)
		if s_ then return { s_, e }, wiseness end
		return { s, e }, wiseness
	end
end

function M:right(bufnr, cursor, match)
	local inner, wiseness = self:get_wiseness(bufnr, match, "inner")
	local s, e = unpack(inner)
	local rp = lists.relative_pos(cursor, inner)
	if rp == "backward" then return end
	return { cursor, rp == "upward" and e or buffers.prev(bufnr, s, wiseness) },
		wiseness
end

function M:left(bufnr, cursor, match)
	local inner, wiseness = self:get_wiseness(bufnr, match, "inner")
	local s, e = unpack(inner)
	local rp = lists.relative_pos(cursor, inner)
	if rp == "forward" then return end
	return {
		rp == "upward" and s or buffers.next(bufnr, e, wiseness),
		buffers.prev(bufnr, cursor, wiseness),
	},
		wiseness
end

function M:get_hints(pos, opts)
	local domain = "outer"
	if
		opts.domain == "inner"
		or opts.domain == "left"
		or opts.domain == "right"
	then
		domain = "inner"
	end
	local start
	local top_line, bot_line = require("flies.utils.editor").win_range()
	if opts.domain == "right" then
		start = pos[1]
	else
		start = top_line + 1
	end
	local end_
	if opts.domain == "left" then
		end_ = pos[1]
	else
		end_ = bot_line
	end
	local matches = {}
	do
		local i = 1
		-- TODO: stop iterating a line end_
		-- TODO: to be exact, we would need to add objects whose start is outside of screen for opts.domain == "right"
		for match in self:iterate_forwards(0, { start, 0 }, pos, opts) do
			if match[domain][1][1] >= end_ then break end
			local skip = false
			local rel = lists.relative_pos(pos, match[domain])
			if opts.domain == "left" and rel == "forward" then skip = true end
			if opts.domain == "right" and rel == "backward" then skip = true end
			if not skip then
				matches[i] = match
				i = i + 1
			end
		end
	end
	local sorter = require("flies.utils.lists").get_upwards_sorter(pos)
	table.sort(matches, sorter)
	local init = not opts.hint_keep_first
			and lists.is_inside(matches[1][domain], pos)
			and 2
		or 1

	local hints = {}
	local n = init + #require("flies").config.hint_keys - 1 - 1
	for i = init, n do
		local match = matches[i]
		if not match then break end
		local range = match[domain]
		local s = (not match.hint_hide_start) and range[1]
		local e = (not match.hint_hide_end) and range[2]
		hints[i - init + 1] = {
			s = s,
			e = e,
			match = match,
		}
	end
	return hints
end

function M:find_upwards(bufnr, pos, opts)
	if self.iterate_upwards then
		if opts.count == 1 then
			return iterators.last()(self:iterate_upwards(bufnr, pos, pos, opts))
		end
		return iterators.nth(opts.count or 1)(
			self:iterate_upwards(bufnr, pos, pos, opts)
		)
	end
end

function M:find_backwards(bufnr, pos, opts)
	if self.iterate_backwards then
		return iterators.nth(opts.count or 1)(
			self:iterate_backwards(bufnr, pos, pos, opts)
		)
	end
end

function M:find_first(bufnr, pos, opts)
	opts.axis = "forward"
	if self.iterate_forwards then
		return iterators.nth(opts.count or 1)(
			self:iterate_forwards(bufnr, { 1, 0 }, pos, opts)
		)
	end
end

function M:find_last(bufnr, pos, opts)
	opts.axis = "backward"
	if self.iterate_backwards then
		return iterators.nth(opts.count or 1)(
			self:iterate_backwards(
				bufnr,
				{ require("flies.utils").infinity, 0 },
				pos,
				opts
			)
		)
	end
end

function M:find_forwards(bufnr, pos, opts)
	if self.iterate_forwards then
		return iterators.nth(opts.count or 1)(
			self:iterate_forwards(bufnr, pos, pos, opts)
		)
	end
end

function M:find_best(bufnr, pos, opts)
	if opts.count then
		if self.nested then return self:find_upwards(bufnr, pos, opts) end
		return self:find_forwards(bufnr, pos, opts)
	end
	return self:find_upwards(bufnr, pos, opts)
		or self:find_forwards(bufnr, pos, opts)
end

local function apply_opts(self, opts, pos, match)
	local wiseness
	local range
	if opts.domain == "inner" then
		range, wiseness = self:get_wiseness(0, match, "inner")
	elseif opts.domain == "left" then
		range, wiseness = self:left(0, pos, match, false)
	elseif opts.domain == "right" then
		range, wiseness = self:right(0, pos, match, false)
	elseif opts.domain == "outer" then
		if opts.around == "always" or opts.around == "solid" and self.solid then
			range, wiseness = self:around(0, match)
		else
			range, wiseness = self:get_wiseness(0, match, "outer")
		end
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
		match = self:find_best(0, pos, opts)
	elseif opts.axis == "upward" then
		match = self:find_upwards(0, pos, opts)
	elseif opts.axis == "forward" then
		match = self:find_forwards(0, pos, opts)
	elseif opts.axis == "first" then
		match = self:find_first(0, pos, opts)
	elseif opts.axis == "backward" then
		match = self:find_backwards(0, pos, opts)
	elseif opts.axis == "last" then
		match = self:find_last(0, pos, opts)
	elseif opts.axis == "hint" then
		local targets = self:get_hints(pos, opts)
		require("flies.utils.hint").hint(
			targets,
			function(match_) cb(apply_opts(self, opts, pos, match_)) end
		)
	else
		error(string.format("unknown axis: %s", opts.axis))
	end
	if not match then return end
	cb(apply_opts(self, opts, pos, match))
end

function M:register(opts)
	local n_opts = vim.tbl_extend("force", opts, { axis = "forward" })
	local p_opts = vim.tbl_extend("force", opts, { axis = "backward" })
	require("flies.operations.move_again").register(
		function() self:move(p_opts) end,
		function() self:move(n_opts) end
	)
end

function M:move(opts)
	self:register(opts)
	self:with_opts(opts, function(params)
		require("flies")._params = params
		local s, e = unpack(params.range)
		s = s or e
		e = e or s
		local mode = require("flies.utils.buffers").get_mode()
		if mode == "x" then
			return buffers.with_x(function()
				-- selection mode
				local vs, ve, wiseness = buffers.get_marks(0, "x")
				if opts.move == "left" then
					vs = buffers.next(0, e, params.wiseness)
					buffers.select2({ ve, vs }, wiseness)
				elseif opts.move == "right" then
					ve = buffers.prev(0, s, params.wiseness)
					buffers.select2({ vs, ve }, wiseness)
				else
					local cursor = buffers.get_cursor()
					if vim.deep_equal(vs, cursor) then
						vs = s
						buffers.select2({ ve, vs }, wiseness)
					else
						-- ok
						ve = e
						buffers.select2({ vs, ve }, wiseness)
					end
				end
			end)
		end
		if mode == "o" then
			-- TODO:
			return
		end
		-- normal mode
		local pos
		if opts.move == "left" then
			pos = s
		elseif opts.move == "right" then
			pos = e
		else
			local cursor = buffers.get_cursor()
			pos = vim.deep_equal(s, cursor) and e or s
		end
		buffers.set_cursor(pos)
	end)
end

function M:select(opts)
	self:register(opts)
	self:with_opts(opts, function(params)
		require("flies")._params = params
		buffers.select(params.range, params.wiseness)
	end)
end

return M

--- fly, the main text seeking abstraction
---@class _Fly : Object
---@field iterate_forwards fun(self: _Fly, bufnr: integer, start: integer[], pos: integer[], opts: opts): fun(): match
---@field iterate_backwards fun(self: _Fly, bufnr: integer, start: integer[], pos: integer[], opts: opts): fun(): match
---@field iterate_upwards fun(self: _Fly, bufnr: integer, start: integer[], pos: integer[], opts: opts): fun(): match
---@field lonely_wiseness_outer wiseness
---@field lonely_wiseness_inner wiseness
local M = require("flies.utils.objects"):new {}

M.nested = false
M.solid = false
M.lonely_wiseness_inner = "v"
M.lonely_wiseness_outer = "v"
M.around_char_pattern = "%s+"
M.around_line_pattern = "^%s*$"
M.lookahead = 200

---@alias match {outer: integer[][], inner: integer[][], context: integer[][]?, around: integer[][]?, around_wiseness: wiseness, hint_hide_start: boolean?, hint_hide_end: boolean?}

local buffers = require "flies.utils.buffers"
local windows = require "flies.utils.windows"
local iterators = require "flies.utils.iterators"
local lists = require "flies.utils.lists"

--- get wiseness of given match
---@param bufnr number
---@param match match
---@param domain domain
---@return integer[][], wiseness
function M:get_wiseness(bufnr, match, domain)
	---type integer[][]
	local range = match[domain]
	local lonely_wiseness = domain == "inner" and self.lonely_wiseness_inner
		or self.lonely_wiseness_outer
	return range, buffers.get_wiseness(bufnr, range, lonely_wiseness)
end

---@param self _Fly
---@param bufnr integer
---@param s integer[]
---@param e integer[]
---@return integer[], integer[]
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

---@param self _Fly
---@param bufnr integer
---@param e integer[]
---@return integer[]?
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

---@param self _Fly
---@param bufnr integer
---@param s integer[]
---@return integer[]?
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

---@param bufnr integer
---@param match match
---@return integer[][], wiseness
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

---@param bufnr integer
---@param cursor integer[]
---@param match match
---@return integer[][]?, wiseness?
function M:right(bufnr, cursor, match)
	local inner, wiseness = self:get_wiseness(bufnr, match, "inner")
	local s, e = unpack(inner)
	local rp = lists.relative_pos(cursor, inner)
	if rp == "backward" then return end
	if rp == "upward" then return { cursor, e }, wiseness end
	return { cursor, buffers.prev_blank(bufnr, s, wiseness) }, wiseness
end

---@param bufnr integer
---@param cursor integer[]
---@param match match
---@return integer[][]?, wiseness?
function M:left(bufnr, cursor, match)
	local inner, wiseness = self:get_wiseness(bufnr, match, "inner")
	local s, e = unpack(inner)
	local rp = lists.relative_pos(cursor, inner)
	if rp == "forward" then return end
	if rp == "upward" then
		return { s, buffers.prev(bufnr, cursor, wiseness) }, wiseness
	end
	return {
		buffers.next_blank(bufnr, e, wiseness),
		buffers.prev(bufnr, cursor, wiseness),
	},
		wiseness
end

function M:ask(cb) return cb() end

---@param pos integer[]
---@param opts opts
---@return {s?: integer[], e?: integer[], match: match}[]
function M:get_hints(pos, opts)
	local domain = "outer"
	if
		opts.domain == "inner"
		or opts.domain == "left"
		or opts.domain == "right"
	then
		domain = "inner"
	end

	opts.axis = "upward"
	local skipped_match = iterators.nth(1)(self:iterate_upwards(0, pos, pos, opts))
	local skipped_range = skipped_match and skipped_match[domain]
	-- this is needed because for solid textobjects interate_upwards has a lookahead
	if skipped_range and not lists.is_inside(skipped_range, pos) then
		skipped_range = nil
	end

	---type integer
	local start
	local top_line, bot_line = windows.get_win_range()
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
	---@type match[]
	local matches = {}
	do
		local i = 1
		-- TODO: to be exact, we would need to add objects whose start is outside of screen for opts.domain == "right"
		-- which would imply to hint the rightmost part of the object
		for match in self:iterate_forwards(0, { start, 0 }, pos, opts) do
			if match[domain][1][1] >= end_ then break end
			local will_take = true
			local match_range = match[domain]
			if match_range then
				if skipped_range then
					if vim.deep_equal(match_range, skipped_range) then will_take = false end
				end
				if will_take then
					matches[i] = match
					i = i + 1
				end
			end
		end
	end
	if #matches == 0 then return {} end
	local sorter = require("flies.utils.lists").get_upwards_sorter(pos)
	table.sort(matches, sorter)
	local init = not opts.hint_keep_first
			and lists.is_inside(matches[1][domain], pos)
			and 2
		or 1

	---@type target[]
	local hints = {}
	local max_hints = require("flies").config.hints.max
	if max_hints == true then
		max_hints = init + #require("flies").config.hint_keys - 1 - 1
	end
	for i, match in ipairs(matches) do
		if max_hints and i > max_hints then break end
		if not match then break end
		local range = match[domain]
		local s = (not match.hint_hide_start) and range[1] or nil
		local e = (not match.hint_hide_end) and range[2] or nil
		hints[i - init + 1] = {
			s = s,
			e = e,
			match = match,
		}
	end
	return hints
end

---@param bufnr integer
---@param pos integer[]
---@param opts opts
---@return match?
function M:find_upwards(bufnr, pos, opts)
	if self.iterate_upwards then
		return iterators.nth(opts.count or 1)(
			self:iterate_upwards(bufnr, pos, pos, opts)
		)
	end
end

---@param bufnr integer
---@param pos integer[]
---@param opts opts
---@return match?
function M:find_backwards(bufnr, pos, opts)
	if self.iterate_backwards then
		return iterators.nth(opts.count or 1)(
			self:iterate_backwards(bufnr, pos, pos, opts)
		)
	end
end

---@param bufnr integer
---@param pos integer[]
---@param opts opts
---@return match?
function M:find_top(bufnr, pos, opts)
	if self.iterate_forwards then
		return iterators.last()(self:iterate_upwards(bufnr, pos, pos, opts))
	end
end

---@param bufnr integer
---@param pos integer[]
---@param opts opts
---@return match?
function M:find_first(bufnr, pos, opts)
	if self.iterate_forwards then
		return iterators.nth(opts.count or 1)(
			self:iterate_forwards(bufnr, { 0, 0 }, pos, opts)
		)
	end
end

---@param bufnr integer
---@param pos integer[]
---@param opts opts
---@return match?
function M:find_last(bufnr, pos, opts)
	if true then
		--TODO:
		print "TODO"
		return
	end
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

---@param bufnr integer
---@param pos integer[]
---@param opts opts
---@return match?
function M:find_forwards(bufnr, pos, opts)
	if self.iterate_forwards then
		return iterators.nth(opts.count or 1)(
			self:iterate_forwards(bufnr, pos, pos, opts)
		)
	end
end

---@param bufnr integer
---@param pos integer[]
---@param opts opts
---@return match?
function M:find_best(bufnr, pos, opts)
	if opts.count then
		if self.nested then return self:find_upwards(bufnr, pos, opts) end
		return self:find_forwards(bufnr, pos, opts)
	end
	return self:find_upwards(bufnr, pos, opts)
		or self:find_forwards(bufnr, pos, opts)
end

---@param self _Fly
---@param opts opts
---@param pos integer[][]
---@param match match
local function get_range(self, opts, pos, match)
	local wiseness
	local range
	if opts.domain == "inner" then
		range, wiseness = self:get_wiseness(0, match, "inner")
	elseif opts.domain == "left" then
		range, wiseness = self:left(0, pos, match)
	elseif opts.domain == "right" then
		range, wiseness = self:right(0, pos, match)
	elseif opts.domain == "outer" then
		if opts.around == "always" or opts.around == "solid" and self.solid then
			range, wiseness = self:around(0, match)
		else
			range, wiseness = self:get_wiseness(0, match, "outer")
		end
	else
		error(string.format("unknown domain: %s", opts.domain))
	end
	return range, wiseness
end

---@alias applied_opts {range: integer[][], wiseness: wiseness, opts: opts, target: _Fly, pos: integer[], match: match}

---comment
---@param opts opts
---@param pos integer[][]
---@return applied_opts?
function M:with_opts(opts, pos)
	if opts.count == 0 then
		if opts.axis == "upward" or (opts.axis == "best" and self.nested == true) then
			opts.axis = "top"
		elseif opts.axis == "backward" then
			opts.axis = "last"
			opts.count = 1
		else
			opts.axis = "first"
			opts.count = 1
		end
	end
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
	elseif opts.axis == "top" then
		match = self:find_top(0, pos, opts)
	elseif opts.axis == "last" then
		match = self:find_last(0, pos, opts)
	elseif opts.axis == "hint" then
		match = opts.match
		-- HACK: this works fine but is hackish
		opts.axis = "forward"
	else
		error(string.format("unknown axis: %s", opts.axis))
	end
	if not match then return end
	local range, wiseness = get_range(self, opts, pos, match)
	return {
		range = range,
		wiseness = wiseness,
		opts = opts,
		target = self,
		pos = pos,
		match = match,
	}
end

---registers a fly for 'flies.actions.move_again'
---@param opts opts
function M:register(opts)
	local n_opts = vim.tbl_extend("force", opts, { axis = "forward" })
	local p_opts = vim.tbl_extend("force", opts, { axis = "backward" })
	require("flies.actions.move_again").register(
		function() self:move(p_opts) end,
		function() self:move(n_opts) end
	)
end

---@param self _Fly
---@param opts opts
---@param pos integer[][]
---@return integer[]?
local function get_point_(self, opts, pos)
	local params = self:with_opts(opts, pos)
	if not params then return end
	local s, e = unpack(params.range)
	if opts.move == "opposite" then return lists.cmp(e, pos) < 0 and s or e end
	if opts.move == "right" then return e or s end
	return s or e
end

---@param self _Fly
---@param opts opts
---@param pos integer[][]
---@return integer[]?
local function get_point(self, opts, pos)
	if opts.count == nil and opts.axis == "best" then
		opts.axis = "upward"
		opts.count = 1
		--TODO: use iterator
		while true do
			local res = get_point_(self, opts, pos)
			if res == nil then
				opts.axis = opts.move == "right" and "forward" or "backward"
				opts.count = 1
				break
			end
			if
				opts.move == "right" and (lists.cmp(pos, res) < 0)
				or opts.move == "left" and (lists.cmp(pos, res) > 0)
			then
				return res
			end
			opts.count = opts.count + 1
		end
	end
	return get_point_(self, opts, pos)
end

--- move cursor
---@param opts opts
function M:move(opts)
	self:register(opts)
	local pos = windows.get_cursor()
	local params
	local res = get_point(self, opts, pos)
	if not res then return end
	local mode = require("flies.utils.buffers").get_mode()
	if mode == "x" then
		return buffers.with_x(function()
			-- selection mode
			local vs, ve, wiseness = buffers.get_marks(0, "x")
			if opts.move == "left" then
				vs = buffers.next(0, res, params.wiseness)
				buffers.select2({ ve, vs }, wiseness)
			elseif opts.move == "right" then
				ve = buffers.prev(0, res, params.wiseness)
				buffers.select2({ vs, ve }, wiseness)
			else
				local cursor = windows.get_cursor()
				if vim.deep_equal(vs, cursor) then
					vs = res
					buffers.select2({ ve, vs }, wiseness)
				else
					ve = res
					buffers.select2({ vs, ve }, wiseness)
				end
			end
		end)
	end
	if mode == "o" then
		-- TODO:
		return
	end
	assert(mode == "n")
	local pos_
	windows.set_cursor(res)
end

--- search and select
---@param opts opts
---@return nil
function M:select(opts)
	local pos = windows.get_cursor()
	local params = self:with_opts(opts, pos)
	if not params then return end
	require("flies")._params = params
	buffers.select(params.range, params.wiseness)
end

return M

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

function M:hop_targets_generator(ref, opts)
	local domain = "outer"
	if
		opts.domain == "inner"
		or opts.domain == "left"
		or opts.domain == "right"
	then
		domain = "inner"
	end
	local use_start_default = opts.domain ~= "right"
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
	do
		local i = 0
		-- TODO: stop iterating a line end_
		-- TODO: to be exact, we would need to add objects whose start is outside of screen for opts.domain == "right"
		for match in self:iterate_forwards(0, { start, 0 }, ref, opts) do
      print(vim.inspect(match[domain]))
      --[[ print("end_", vim.inspect(end_)) ]]
			if match[domain][1][1] >= end_ then break end
			local skip = false
			local rel = lists.relative_pos(cursor_pos, match[domain])
			if opts.domain == "left" and rel == "forward" then skip = true end
			if opts.domain == "right" and rel == "backward" then skip = true end
			if not skip then
				i = i + 1
				local use_start = match.hint_use_start
				if use_start == nil then use_start = use_start_default end
				local h = match[domain][use_start and 1 or 2]
				local line = h[1] - 1
				local column = h[2]
				jump_targets[i] = {
					line = line,
					column = column,
					window = 0,
					object = match,
				}
			end
		end
	end
	local indirect_jump_targets = {}
	for i, jump_target in ipairs(jump_targets) do
		indirect_jump_targets[i] = {
			index = i,
			score = -manh_dist({ jump_target.line, jump_target.column }, cursor_pos),
		}
	end

	return {
		jump_targets = jump_targets,
		indirect_jump_targets = indirect_jump_targets,
	}
end

function M:find_upwards(bufnr, count, pos, opts)
	if self.iterate_upwards then
		return iterators.nth(count)(self:iterate_upwards(bufnr, pos, pos, opts))
	end
end

function M:find_backwards(bufnr, count, pos, opts)
	if self.iterate_backwards then
		return iterators.nth(count)(self:iterate_backwards(bufnr, pos, pos, opts))
	end
end

function M:find_forwards(bufnr, count, pos, opts)
	if self.iterate_forwards then
		return iterators.nth(count)(self:iterate_forwards(bufnr, pos, pos, opts))
	end
end

function M:find_best(bufnr, pos, opts)
	return self:find_upwards(bufnr, 1, pos, opts) or self:find_forwards(bufnr, 1, pos, opts)
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
		match = self:find_upwards(0, opts.count or 1, pos, opts)
	elseif opts.axis == "forward" then
		match = self:find_forwards(0, opts.count or 1, pos, opts)
	elseif opts.axis == "backward" then
		match = self:find_backwards(0, opts.count or 1, pos, opts)
	elseif opts.axis == "hint" then
		require("hop").hint_with_callback(
			function() return self:hop_targets_generator(pos, opts) end,
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
		require("flies")._params = params
		buffers.move(params.range, true)
	end)
end

function M:select(opts)
	self:with_opts(opts, function(params)
		require("flies")._params = params
		buffers.select(params.range, params.wiseness)
	end)
end

return M

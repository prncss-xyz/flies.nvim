local M = require("flies.flies._fly"):new {}

M.nested = true

M.lonely_wiseness_around = "V"

local lists = require "flies.utils.lists"
local ts = require "flies.utils.ts"
local iterators = require "flies.utils.iterators"
local buffers = require "flies.utils.buffers"

local function find_best_context(pos, matches, axis, many)
	local best, pre
	local cmp = lists.sort_axis("upward", "context")
	for _, match in ipairs(matches) do
		if lists.relative_pos(pos, match.context) == "upward" then
			if not many or pre and vim.deep_equal(match.context, pre.context) then
				if not best or cmp(match, best) then best = match end
			else
				pre = match
			end
		end
	end
	if best then return best.context end
	if axis == "upward" then return end
	pre = nil
	cmp = lists.sort_axis(axis, "context")
	for _, match in ipairs(matches) do
		if lists.relative_pos(pos, match.context) == axis then
			if not many or pre and vim.deep_equal(match.context, pre.context) then
				if not best or cmp(match, best) then best = match end
			else
				pre = match
			end
		end
	end
	return best.context
end

function M:get_wiseness(bufnr, match, domain)
	local range = match[domain]
	local lonely_wiseness = domain == "inner" and self.lonely_wiseness_inner
		or self.lonely_wiseness_outer
	return range, buffers.get_wiseness(bufnr, range, lonely_wiseness)
end

local function get_around(self, bufnr, match, matches)
	-- latest end before match start
	-- nil if first match
	local lebs
	-- earliest start before match end
	-- nil if last match
	local esbe
	local context = match.context
	local match_s, match_e = unpack(match.outer)
	for _, m in ipairs(matches) do
		-- amongst matches of the same context
		if vim.deep_equal(m.context, context) then
			-- ie, as < match_s < match_e < ae, is
			local is, ie = unpack(m.outer)
			-- finds the latest end before match start
			if lists.cmp(ie, match_s) < 0 then
				if not lebs or lists.cmp(ie, lebs) > 0 then lebs = ie end
			end
			-- finds the earliest start before match end
			if lists.cmp(match_e, is) < 0 then
				if not esbe or lists.cmp(is, esbe) < 0 then esbe = is end
			end
		end
	end

	local wiseness_range_s = lebs and lebs or context[1]
	local wiseness_range_e = esbe and buffers.prev(bufnr, esbe, "v") or context[2]
	local wiseness = buffers.get_wiseness(
		bufnr,
		{ wiseness_range_s, wiseness_range_e },
		self.lonely_wiseness_around
	)
	local s = lebs and buffers.next(bufnr, lebs, wiseness) or context[1]
	local e
	if esbe then
		if lebs then
			e = match_e
		else
			e = buffers.prev(bufnr, esbe, "v")
		end
	else
		e = context[2]
	end

	local range = { s, e }
	return range, wiseness
end

local function iter_axis(axis)
	return function(self, bufnr, pos, ref)
		local matches = ts.query_from_name(bufnr, self.names)
		if matches == nil then
			if self.no_tree then
				--TODO: make static
				return self.no_tree[string.format("iterate_%ss", axis)](self, bufnr, pos)
			end
			return iterators.null()
		end
		local ctx = matches[1] and matches[1].context
		local best_context
		if ctx then
			best_context = find_best_context(ref, matches, axis, self.many)
			if not best_context then return iterators.null() end
		end
		local matches_filtered = vim.tbl_filter(function(match)
			if best_context then
				if not vim.deep_equal(best_context, match.context) then return false end
			end
			return lists.relative_pos(pos, match.outer) == axis
		end, matches)
		table.sort(matches_filtered, lists.sort_axis(axis))

		if ctx then
			for _, match in ipairs(matches_filtered) do
				match.around, match.around_wiseness =
					get_around(self, bufnr, match, matches)
			end
		end
		return iterators.from_list_single(matches_filtered)
	end
end

M.iterate_upwards = iter_axis "upward"
M.iterate_forwards = iter_axis "forward"
M.iterate_backwards = iter_axis "backward"

return M

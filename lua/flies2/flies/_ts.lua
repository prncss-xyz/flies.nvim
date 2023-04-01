local M = require("flies2.flies._fly"):new {}

local lists = require "flies2.utils.lists"
local ts = require "flies2.utils.ts"
local iterators = require "flies2.utils.iterators"
local buffers = require "flies2.utils.buffers"

local function find_best(pos, matches, axis)
	local best
	local cmp = lists.sort_axis "upward"
	for _, match in ipairs(matches) do
		if lists.relative_pos(pos, match.outer) == "upward" then
			if not best or cmp(match, best) then best = match end
		end
	end
	if best or axis == "upward" then return best end
	cmp = lists.sort_axis(axis)
	for _, match in ipairs(matches) do
		if lists.relative_pos(pos, match.outer) == axis then
			if not best or cmp(match, best) then best = match end
		end
	end
	return best
end

-- TODO: wiseness
local function get_around(bufnr, match, matches)
	local as, ae
	local context = match.context
	local match_s, match_e = unpack(match.outer)
	for _, m in ipairs(matches) do
		if vim.deep_equal(m.context, context) then
			-- ie, as < match_s < match_e < ae, is
			local is, ie = unpack(m.outer)
			if lists.cmp(ie, match_s) < 0 then
				if not as or lists.cmp(ie, as) > 0 then as = ie end
			end
			if lists.cmp(match_e, is) < 0 then
				if not ae or lists.cmp(is, ae) < 0 then ae = is end
			end
		end
	end
	if ae then
		local wiseness = "v"
		ae = buffers.prev(bufnr, ae, wiseness)
	else
		ae = context[2]
	end
	if lists.cmp(match_e, ae) < 0 then return { match_s, ae } end
	if as then
		local wiseness = "v"
		as = buffers.next(bufnr, as, wiseness)
	else
		as = context[1]
	end
	return { as, match_e }
end

local function iter_axis(axis)
	return function(self, bufnr, pos, ref)
		local matches = ts.query_from_name(bufnr, self.names)
		if matches == nil then
			if self.no_tree then
				return self.no_tree[string.format("iterate_%ss", axis)](self, bufnr, pos)
			end
			return iterators.null()
		end
		local ctx = matches[1] and matches[1].context
		local best_context
		if ref and ctx then
			local best = find_best(ref, matches, axis)
			if not best then return iterators.null() end
			if best then best_context = best.context end
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
				match.around = get_around(bufnr, match, matches)
			end
		end
		return iterators.from_list_single(matches_filtered)
	end
end

M.iterate_upwards = iter_axis "upward"
M.iterate_forwards = iter_axis "forward"
M.iterate_backwards = iter_axis "backward"

return M

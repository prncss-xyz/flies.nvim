---@class _Ts: _Fly
---@field names string[]
---@field no_tree _Fly
---@field ctx_pre boolean?
local M = require("flies.flies._fly"):new {}

M.nested = true

M.lonely_wiseness_around = "V"

local lists = require "flies.utils.lists"
local ts = require "flies.utils.ts"
local iterators = require "flies.utils.iterators"
local buffers = require "flies.utils.buffers"

---@param bufnr number
---@param match match
---@param domain domain
---@return integer[][], wiseness
function M:get_wiseness(bufnr, match, domain)
	local range = match[domain]
	local lonely_wiseness = domain == "inner" and self.lonely_wiseness_inner
		or self.lonely_wiseness_outer
	return range, buffers.get_wiseness(bufnr, range, lonely_wiseness)
end

---TODO: include trailing comma in query and search backward

---@param self _Ts
---@param bufnr integer
---@param match match
---@return integer[][]?, wiseness?
local function get_around(self, bufnr, match, matches)
	local as, ae
	local context = match.context
	if not context then return nil, nil end
	local match_s, match_e = unpack(match.outer)
	for _, match_ in ipairs(matches) do
		if vim.deep_equal(match_.context, context) then
			-- ie, as < match_s < match_e < ae, is
			local is, ie = unpack(match_.outer)
			if lists.cmp(ie, match_s) < 0 then
				if not as or lists.cmp(ie, as) > 0 then as = ie end
			end
			if lists.cmp(match_e, is) < 0 then
				if not ae or lists.cmp(is, ae) < 0 then ae = is end
			end
		end
	end

	as = as and buffers.next(bufnr, as, "v") or context[1]
	ae = ae and buffers.prev(bufnr, ae, "v") or context[2]
	local range
	local first
	if
		self.ctx_pre and (not vim.deep_equal(as, match_s))
		or not self.ctx_pre and vim.deep_equal(match_e, ae)
	then
		range = { as, match_e }
	else
		range = { match_s, ae }
	end
	return range, buffers.get_wiseness(bufnr, range, self.lonely_wiseness_around)
end

---@param axis axis
local function iter_axis(axis)
	---@param self _Ts
	---@param bufnr integer
	---@param pos integer[][]
	---@param ref integer[][]
	return function(self, bufnr, pos, ref)
		local matches = ts.query_from_name(bufnr, self.names)
		if matches == nil then
			if self.no_tree then
				--TODO: make static
				return self.no_tree[string.format("iterate_%ss", axis)](self, bufnr, pos)
			end
			return iterators.null()
		end
		local matches_filtered = vim.tbl_filter(
			function(match) return lists.relative_pos(pos, match.outer) == axis end,
			matches
		)
		table.sort(matches_filtered, lists.sort_axis(axis))
		for _, match in ipairs(matches_filtered) do
			match.around, match.around_wiseness = get_around(self, bufnr, match, matches)
		end
		return iterators.from_list_single(matches_filtered)
	end
end

M.iterate_upwards = iter_axis "upward"
M.iterate_forwards = iter_axis "forward"
M.iterate_backwards = iter_axis "backward"

return M

local M = require("flies2.flies._fly"):new {}

local lists = require "flies2.utils.lists"
local ts = require "flies2.utils.ts"
local iterators = require "flies2.utils.iterators"
local buffers = require "flies2.utils.buffers"

local function spice_match(bufnr, match)
	local match_out = {}
	for k, v in pairs(match) do
		local name, mod = unpack(vim.split(k, ".", { plain = true }))
		if mod == "node_inside" then
			match_out[name] = ts.get_node_inside(bufnr, v)
		elseif mod == "node_second" then
			match_out[name] = ts.get_node_second(bufnr, v)
		elseif mod == "before" then
			local r = match_out[name] or {}
			r[1] = buffers.next(bufnr, v[2], "v")
			match_out[name] = r
		elseif mod == "after" then
			local r = match_out[name] or {}
			r[2] = buffers.prev(bufnr, v[1], "v")
			match_out[name] = r
		else
			match_out[k] = v
		end
	end
	match_out.inner = match_out.inner or match_out.outer
	return match_out
end

local function find_best(pos, matches)
	local best
	local cmp = lists.sort_axis "upward"
	for _, match in ipairs(matches) do
		if lists.relative_pos(pos, match.outer) == "upward" then
			if not best or cmp(match, best) then best = match end
		end
	end
	if best then return best end
	cmp = lists.sort_axis "forward"
	for _, match in ipairs(matches) do
		if lists.relative_pos(pos, match.outer) == "forward" then
			if not best or cmp(match, best) then best = match end
		end
	end
	return best
end

local function iter_axis(axis)
	return function(self, bufnr, pos, ref)
		local matches = ts.query_from_name(bufnr, self.name)
		if matches == nil then
			if self.no_tree then
				return self.no_tree[string.format("iterate_%ss", axis)](self, bufnr, pos)
			end
			return iterators.null()
		end
		matches = vim.tbl_map(
			function(match) return spice_match(bufnr, match) end,
			matches
		)
		matches = vim.tbl_filter(
			function(match) return lists.relative_pos(pos, match.outer) == axis end,
			matches
		)
		table.sort(matches, lists.sort_axis(axis))
		local context
		if ref then
			local base = find_best(ref, matches)
			context = base and base.context
		else
			context = matches[1] and matches[1].context
		end
		if context then
			matches = vim.tbl_filter(
				function(match)
					return lists.cmp(match.context[1], context[1]) == 0
						and lists.cmp(match.context[2], context[2]) == 0
				end,
				matches
			)
			for i, match in ipairs(matches) do
				local next = matches[i + 1] and matches[i + 1].outer[1] or context[2]
				if lists.cmp(match.outer[2], next) then
					match.arount = { match.outer[1], next }
				else
					local prev = matches[i - 1] and matches[i - 1].outer[2] or context[1]
					match.around = { prev, match.outer[2] }
				end
			end
		end
		return iterators.from_list_single(matches)
	end
end

M.iterate_upwards = iter_axis "upward"
M.iterate_forwards = iter_axis "forward"
M.iterate_backwards = iter_axis "backward"

return M

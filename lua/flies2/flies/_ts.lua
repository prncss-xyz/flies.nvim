local M = require("flies2.flies._fly"):new {}

local lists = require "flies2.utils.lists"
local ts = require "flies2.utils.ts"
local iterators = require "flies2.utils.iterators"
local buffers = require "flies2.utils.buffers"

function M:map(match) return match end

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

local function iter_axis(axis)
	return function(self, bufnr, pos)
		local matches = ts.query_from_name(bufnr, self.name)
		if matches == nil then
			if self.no_tree then
				return self.no_tree[string.format("iterate_%ss", axis)](self, bufnr, pos)
			end
			return iterators.null()
		end
		local matches_ = {}
		for _, match in ipairs(matches) do
			match = spice_match(bufnr, match)
			if lists.relative_pos(pos, match.outer) == axis then
				match = self:map(match)
				if match then table.insert(matches_, match) end
			end
		end
		table.sort(matches_, lists.sort_axis(axis))
		return iterators.from_list_single(matches_)
	end
end

M.iterate_upwards = iter_axis "upward"
M.iterate_forwards = iter_axis "forward"
M.iterate_backwards = iter_axis "backward"

return M

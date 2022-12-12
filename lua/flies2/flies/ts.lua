local M = require("flies2.flies._fly"):new {}

local lists = require "flies2.utils.lists"
local ts = require "flies2.utils.ts"
local iterators = require "flies2.utils.iterators"

function M:map(match) return match end

local function iter_axis(axis)
	return function(self, bufnr, pos)
		local matches = ts.query(bufnr, self.name)
		if matches == nil then
			if self.no_tree then
				return self.no_tree[string.format("iterate_%ss", axis)](self, bufnr, pos)
			else
				return iterators.null()
			end
		end
		local matches_ = {}
		for _, match in ipairs(matches) do
			if lists.relative_pos(pos, match) == axis then
				match = self:map(match)
				if match then table.insert(matches_, match) end
			end
		end
		table.sort(matches_, lists.cmp_axis(axis))
		return iterators.from_list_single(matches_)
	end
end

M.iterate_upwards = iter_axis "upward"
M.iterate_forwards = iter_axis "forward"
M.iterate_backwards = iter_axis "backward"

return M

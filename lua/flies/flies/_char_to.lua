---@class _CharTo: _Fly
local M = require("flies.flies._subline"):new {}

M.solid = true

local function cb(ref, _)
	return function(match)
		local after
		local point = match.outer[1]
		local inner, outer
		if require("flies.utils.lists").cmp(point, ref) < 0 then
			after = true
			outer = { point, require("flies.utils.buffers").prev(0, ref, "v") }
			inner = {
				require("flies.utils.buffers").next(0, point, "v"),
				require("flies.utils.buffers").prev(0, ref, "v"),
			}
		else
			after = false
			local mode = require("flies.utils.buffers").get_mode()
			outer = { ref, point }
			inner = { ref, require("flies.utils.buffers").prev(0, point, "v") }
		end
		return {
			inner = inner,
			outer = outer,
			hint_use_start = after,
			hint_hide_start = not after,
			hint_hide_end = after,
		}
	end
end

function M:iterate_upwards(bufnr, pos, ref, opts)
	return require("flies.utils.iterators").null()
end

function M:iterate_backwards(bufnr, pos, ref, opts)
	return require("flies.utils.iterators").map(cb(ref, opts))(
		self:super("iterate_backwards", bufnr, pos, ref, opts)
	)
end

function M:iterate_forwards(bufnr, pos, ref, opts)
	return require("flies.utils.iterators").map(cb(ref, opts))(
		self:super("iterate_forwards", bufnr, pos, ref, opts)
	)
end

return M

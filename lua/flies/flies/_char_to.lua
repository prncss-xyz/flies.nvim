local M = require("flies.flies._subline"):new {}

M.solid = true

local function cb(ref, opts)
	return function(match)
		local hint_use_start
		local point = match.outer[1]
		local range
		if require("flies.utils.lists").cmp(point, ref) < 0 then
			hint_use_start = true
			range = { point, require("flies.utils.buffers").prev(0, ref, "v") }
		else
			hint_use_start = false
			if opts.incl then
				range = { ref, point }
			else
				range = { ref, require("flies.utils.buffers").prev(0, point, "v") }
			end
		end
		return { inner = range, outer = range, hint_use_start = hint_use_start }
	end
end

function M:iterate_upwards(bufnr, pos, ref, opts)
	return require("flies.utils.iterators").map(cb(ref, opts))(
		self:super("iterate_upwards", bufnr, pos, ref, opts)
	)
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

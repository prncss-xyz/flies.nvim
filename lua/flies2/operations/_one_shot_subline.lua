local M = require("flies2.operations._one_shot"):new {}

-- TODO: multiple captures
-- TODO: reuse
-- TODO: remove bufnr from buffers edits
-- TODO: update tests

function M:new(t)
	local o = self:super("new", { cbs = {} })
	local patterns = {}
	for i, v in ipairs(t) do
		patterns[i] = v[1]
		o.cbs[i] = v[2]
	end
	o.target = require("flies2.flies._subline"):new {
		patterns = patterns,
	}
	return o
end

function M:op_func(match)
	if not match then return end
	local cb = self.cbs[match.index]
	if cb then cb(match) end
end

return M

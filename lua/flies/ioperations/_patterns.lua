---@class _Patterns : _IOperation
---@field cbs fun(target: table)[]
local M = require("flies.ioperations._ioperation"):new {}

-- TODO: multiple captures

---@param target _Fly
---@param cbs fun(m: table)[]
local function from_rules(target, cbs)
	return M:new {
		cbs = cbs,
		target = target,
		op_func = function(self, match)
			if not match then return end
			local contents = require("flies.utils.buffers").get_range(0, match.outer)
			local cb = self.cbs[match.index]
			if cb then cb(contents) end
		end,
	}
end

---@param rules {pattern: string, cb: fun(m: table)}[]
function M.from_rules(rules)
	local patterns = {}
	local cbs = {}
	for i, v in ipairs(rules) do
		patterns[i] = v[1]
		cbs[i] = v[2]
	end
	---@class _Subline
	local target = require("flies.flies._subline"):new {
		patterns = patterns,
	}
	return from_rules(target, cbs), from_rules(target, cbs)
end

return M

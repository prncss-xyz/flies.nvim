---@class Subline : _IOperation
---@field cbs fun(fwd: boolean, target: table)[]
---@field fwd boolean
local M = require("flies.ioperations._ioperation"):new {}

-- TODO: multiple captures

---@param fwd boolean
---@param target Fly
---@param cbs fun(m: table)[]
local function from_rules(fwd, target, cbs)
	return M:new {
		cbs = cbs,
		target = target,
		op_func = function(self, match)
			if not match then return end
			local cb = self.cbs[match.index]
			if cb then cb(fwd, match) end
		end,
	}
end

---@param rules {pattern: string, cb: fun(fwd: boolean, m: table)}[]
function M.from_rules(rules)
	local patterns = {}
	local cbs = {}
	for i, v in ipairs(rules) do
		patterns[i] = v[1]
		cbs[i] = v[2]
	end
  ---@class _Fly
	local target = require("flies.flies._subline"):new {
		patterns = patterns,
	}
	return from_rules(true, target, cbs), from_rules(false, target, cbs)
end

return M

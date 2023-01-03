local M = {}

local mt = {}

function mt.__index(_, key)
	local ok, m = pcall(require, string.format("flies2.ts_queries.%s", key))
	if ok then return m end
end

setmetatable(M, mt)

return M

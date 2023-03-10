local M = {}

local mt = {}
function mt.__index(_, key)
	if key == "typescript" then return require "flies2.ts_queries.typescript" end
	if key == "javascript" then return require "flies2.ts_queries.javascript" end
	if key == "lua" then return require "flies2.ts_queries.lua" end
end

setmetatable(M, mt)

return M

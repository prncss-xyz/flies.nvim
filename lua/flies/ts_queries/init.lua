local M = {}

local mt = {}
function mt.__index(_, key)
	if key == "javascript" then return require "flies.ts_queries.javascript" end
	if key == "javascriptreact" then
		return require "flies.ts_queries.javascriptreact"
	end
	if key == "typescript" then return require "flies.ts_queries.typescript" end
	if key == "lua" then return require "flies.ts_queries.lua" end
	if key == "go" then return require "flies.ts_queries.go" end
	if key == "markdown" then return require "flies.ts_queries.markdown" end
end

setmetatable(M, mt)

return M

local M = {}

local query = require "flies2.utils.query"

local function select(opts) opts.target:select(opts) end

function M.exec(opts, override)
	opts = query.query_obj(opts, override)
	if not opts then return end
	select(opts)
end

return M

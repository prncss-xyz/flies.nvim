local M = {}

local query = require "flies.utils.query"

local function select(opts) opts.target:select(opts) end

function M.select(opts, override)
	opts = query.query_obj(opts, override)
	if not opts then return end
	select(opts)
end

return M

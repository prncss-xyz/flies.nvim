local M = {}

local query = require "flies.utils.query"

local function select(opts)
	opts.target:select(opts)
end

function M.exec(opts, override)
	opts = query.query_obj(opts, override)
	select(opts)
end

return M

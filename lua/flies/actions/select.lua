local M = {}

local query = require "flies.utils.query"

local function select(opts) opts.target:select(opts) end

function M.select(opts, override) query.query_obj(opts, override, false, select) end

return M

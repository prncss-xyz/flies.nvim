local M = {}

local ask = require "flies.utils.ask"

local function select(opts) opts.target:select(opts) end

function M.select(opts, override) ask.ask(opts, override, false, select) end

return M

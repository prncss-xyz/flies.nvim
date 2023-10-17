---@class Explode: _Operator
local M = require("flies.operations._operator"):new {}

local sandwich = require("flies.utils.sandwich").sandwich

function M:run(params) sandwich(self, params, false, true) end

M.default_opts = { domain = "outer", around = "never" }

return M

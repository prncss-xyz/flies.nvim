---@class Brackets: _Subline
local M = require("flies.flies._subline"):new {}

M.nested = true
M.patterns = { "%b()", "%b[]", "%b{}" }

function M:map(_, _, _, s, e) return s + 1, e - 1 end

return M

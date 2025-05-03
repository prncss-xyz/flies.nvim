---@class CharToAny: _Fly
local M = require("flies.flies._subline"):new {}

M.solid = true
M.name = "CharToAny"
M.patterns = { "%S" }
M.around_char_pattern = false

return M

---@class CharToAny: _Fly
local M = require("flies.flies._subline"):new {}

M.name = "CharToAny"
M.patterns = { "%S" }
M.around_char_pattern = false

---type string?
local chars

return M

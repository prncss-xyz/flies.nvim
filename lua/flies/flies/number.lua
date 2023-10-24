---@class Number: _Subline
local M = require("flies.flies._subline"):new {}

M.solid = true

-- number, needs to work with natural languages and inside identifiers
-- if you want to match number litterals in your language, use a treesitter query

M.patterns = {
	"%-?[%d]*%d%.[%d]*%d", -- float
	"%-?[%d]+", -- decimal, octal
}

return M

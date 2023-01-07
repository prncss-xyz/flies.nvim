local M = require("flies2.flies._subline"):new {}

M.solid = true

M.around_char_pattern = "%.+"

M.patterns = {
	"[%w]+%f[%.]",
	"%f[.][%w]+",
}

return M

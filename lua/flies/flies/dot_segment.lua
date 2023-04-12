local M = require("flies.flies._subline"):new {}

M.solid = true

M.around_char_pattern = "%.+"

M.patterns = {
	"%w+%f[.]",
	"%f[^.]%w+",
}

return M

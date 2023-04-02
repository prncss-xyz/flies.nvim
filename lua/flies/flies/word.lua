local M = require("flies.flies._subline"):new {}

M.solid = true

M.patterns = { "[%w_]+", "%p+" }

return M

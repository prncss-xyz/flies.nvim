local M = require("flies2.flies._subline"):new {}

M.solid = true

M.patterns = { "[%w_]+", "%p+" }

return M

local M = require("flies.flies.word"):new {}

local pattern = M.patterns[1]

M.patterns = { pattern, "%p+" }

return M

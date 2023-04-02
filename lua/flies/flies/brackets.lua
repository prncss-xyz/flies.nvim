local M = require("flies.flies._pair"):new {}

M.left_patterns = { "%(", "%[", "{" }
M.right_patterns = { "%)", "%]", "}" }

return M

local M = require("flies2.flies._pair"):new {}

M.left_patterns = { "<(%w+)[^/>]*>" }
M.right_patterns = { "</(%w+)>" }
M.validator = function(_, m1, _, m2) return m1:lower() == m2:lower() end

return M

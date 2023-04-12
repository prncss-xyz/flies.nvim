local M = require("flies.flies._pair"):new {}

-- current limitation: tag must be single line

M.left_patterns = {
	"<([%w_]+)[^/>]*>",
	"{{#([%w_]+)}}",
	"{{#([%w_]+)%?}}",
	"<%%%%",
	"<%%[=#]?-?",
}
M.right_patterns =
	{ "</([%w_]+)>", "{{/([%w_]+)}}", "{{/([%w_]+)%?}}", "%%%%>", "-?%%>" }

M.validator = function(i, m1, j, m2)
	if i ~= j then return end
	if m1 and m2 then return m1:lower() == m2:lower() end
	return true
end

return M

local M = require("flies2.flies._subline"):new {}

M.solid = true

M.patterns = {
	"%w+%f[_]",
	"%f[^_]%w+",
	"%l+%f[%u]",
	"%u%l+$",
	"%u%l+%f[%u]",
  "%f[%u]%u+"
	--TODO: UUUUaa
}

return M

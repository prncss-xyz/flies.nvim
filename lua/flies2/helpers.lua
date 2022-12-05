local M = {}

function M.from_pattern(pattern)
	return function(line, init) return line:find(pattern, init) end
end

return M

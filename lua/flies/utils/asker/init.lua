local M = {}

function M.asker()
	local esc = require("flies.utils.editor").esc
	return function()
		local char = vim.fn.nr2char(vim.fn.getchar())
		if char == esc then return end
		return char
	end
end

function M.process(acc, reducer, extract)
	for char in M.asker() do
		local status, res = reducer(acc, char)
		if status == "failure" then break end
		if status == "success" then
			if extract then return extract(res) end
			return res
		end
		acc = res
	end
end

return M

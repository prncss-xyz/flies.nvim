local M = {}

-- biggest integer in lua JIT
-- source: http://lua-users.org/wiki/IntegerDomain
M.infinity = 9007199254740992

function M.pattern_escape(str, smart_case)
	-- disable case insensitivity if there is an uppercase
	if smart_case and str:match "%u" then smart_case = false end
	local res = ""
	for i = 1, #str do
		local char = string.sub(str, i, i)
		if char:match "%p" then
			res = res .. "%" .. char
		elseif char == "\r" then
			res = res .. "$"
		elseif char:match "%l" then
			res = res .. "[" .. char .. char:upper() .. "]"
		else
			res = res .. char
		end
	end
	return res
end

function M.correct_indent(in_str, new_indent)
	local out_str
	local old_indent
	local lines = vim.split(in_str, "\n", { plain = true })
	for i, line in ipairs(lines) do
		local new_line
		local line_indent = line:match "^%s*"
		-- if line contains only splace characters
		if line == line_indent then
			if i == #lines then break end
			new_line = ""
		else
			if not old_indent then old_indent = line_indent end
			-- if line does not start with commont indent, don't transform anything
			if not vim.startswith(line_indent, old_indent) then return in_str end
			-- replace common indent with provided indent
			new_line = new_indent .. line:sub(old_indent:len() + 1)
		end
		if out_str then
			out_str = out_str .. "\n" .. new_line
		else
			out_str = new_line
		end
	end
	return out_str
end

return M

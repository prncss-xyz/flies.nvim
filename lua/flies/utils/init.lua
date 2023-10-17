local M = {}

-- source: http://lua-users.org/wiki/IntegerDomain
--- representing infinity with the largest possible positive (lua JIT specific)
M.infinity = 9007199254740992

--- converts a plain text search to the equivalent lua pattern
---@param plain_search string
---@param smart_case boolean wether to disable case insensitivity if there is an uppercase is search string
---@return string
function M.pattern_escape(plain_search, smart_case)
	if smart_case and plain_search:match "%u" then smart_case = false end
	local res = ""
	for i = 1, #plain_search do
		local char = string.sub(plain_search, i, i)
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

--- replace indentation space of a multiple-line string with provided indent
---@param indent string
---@param str string
---@return string
function M.correct_indent(indent, str)
	local out_str
	local old_indent
	local lines = vim.split(str, "\n", { plain = true })
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
			if not vim.startswith(line_indent, old_indent) then return str end
			-- replace common indent with provided indent
			new_line = indent .. line:sub(old_indent:len() + 1)
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

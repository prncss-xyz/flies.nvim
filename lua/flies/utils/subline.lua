local M = {}

---@alias sublinePattern string|fun(self: _Fly, line: string, init: integer)
---@alias sublineMatch {[1]: integer, [2]: integer, [3]: integer, [4]: any}

---@param patterns sublinePattern[]
---@param line string
---@return sublineMatch[]
function M.get_matches(self, patterns, line)
	---type sublineMatch[]
	local matches = {}
	---type sublineMatch[]
	local res = {}
	local init = 1
	---type ("init"|"active"|"done")[]
	local state = {}
	for i_, _ in ipairs(patterns) do
		state[i_] = "init"
	end
	while true do
		---type integer?
		local i
		for i_, pattern in ipairs(patterns) do
			if state[i_] == "init" or (state[i_] == "active") and res[i_][2] < init then
				state[i_] = "active"
				local s, e, capture
				if type(pattern) == "string" then
					s, e, capture = line:find(pattern, init)
				else
					s, e, capture = pattern(self, line, init)
				end
				if s then
					assert(e, "shoud be defined too")
					res[i_] = { i_, s, e, capture }
				else
					state[i_] = "done"
				end
			end
			if state[i_] == "active" then
				if not i or res[i_][2] < res[i][2] then i = i_ end
			else
				assert(state[i_] == "done", "faulty logic")
			end
		end
		if not i then return matches end
		table.insert(matches, res[i])
		init = res[i][3] + 1
	end
end

return M

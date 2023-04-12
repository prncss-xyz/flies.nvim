local M = require("flies.flies._subline"):new {}

M.solid = true

M.around_char_pattern = "_+"

local Mode = {
	approach = "approach",
	lower = "lower",
	first_cap = "first_cap",
	all_caps = "all_caps",
}

local function pattern(_, line, init)
	local s, e
	local mode = Mode.approach
	-- after iterating all chars, will send an empty string for end of line
	for i = init, #line + 1 do
		local char = line:sub(i, i)
		if mode == Mode.approach then
			if char:match "%l" then
				mode = Mode.lower
				s = i
			elseif char:match "%u" then
				mode = Mode.first_cap
				s = i
			end
		else
			if char == "_" then return s, e end
			if char == "" or char:match "[%s%p]" then
				if line:sub(s - 1, s - 1):match "[%a_]" then return s, e end
				mode = Mode.approach
			elseif char:match "%D" then
				if mode == Mode.all_caps then
					if char:match "%l" then return s, e - 1 end
				elseif mode == Mode.lower then
					if char:match "%u" then return s, e end
				-- mode == Mode.first_cap
				elseif char:match "%l" then
					mode = Mode.lower
				elseif char:match "%u" then
					mode = Mode.all_caps
				end
			end
		end
		e = i
	end
end

M.patterns = { pattern }

return M

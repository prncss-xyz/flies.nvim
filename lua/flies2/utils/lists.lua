local M = {}

---lexicoraphical comparaison between tuples
function M.cmp(t1, t2)
	local i = 1
	while true do
		local v1, v2 = t1[i], t2[i]
		if v1 == nil then
			if v2 == nil then return 0 end
			return -1
		end
		if v2 == nil then return 1 end
		if v1 < v2 then return -1 end
		if v1 > v2 then return 1 end
		i = i + 1
	end
end

--- axis of a range relative to position
---@param pos table reference (cursor) positon
---@param s table start of range
---@param e table end of range
---@return string backward\forward\upward
function M.relative_pos(pos, to)
	local range = to.outer
	if M.cmp(range[2], pos) < 0 then return "backward" end
	if M.cmp(pos, range[1]) < 0 then return "forward" end
	return "upward"
end

---given a function that maps values to tuples, returns a comparing function
---for values that corresponds to lexicoraphical order of resulting tuples
function M.cmp_gen(cb)
	return function(a, b) return M.cmp(cb(a), cb(b)) end
end

function M.cmp_axis(dir)
	if dir == "upward" then
		return M.cmp_gen(function(to)
			local a = to.outer
			return { a[1][1], a[1][2], -a[2][1], -a[2][2] }
		end)
	elseif dir == "forward" then
		return M.cmp_gen(function(to)
			local a = to.outer
			return { -a[2][1], -a[2][2], -a[1][1], -a[1][2] }
		end)
	elseif dir == "backward" then
		return M.cmp_gen(function(to)
			local a = to.outer
			return { a[1][1], a[1][2], a[2][1], a[2][2] }
		end)
	end
end

local function ripairs(s, i)
	i = i - 1
	if i > 0 then return i, s[i] end
end

--- reversed ipairs
---@param t table list
function M.ripairs(t) return ripairs, t, #t + 1 end

--- bidirectional ipairs
---@param t table list
function M.bipairs(fwd, t)
	if fwd then
		return ipairs(t)
	else
		return M.ripairs(t)
	end
end

return M

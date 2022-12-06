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
function M.relative_pos(pos, s, e)
	if M.cmp(e, pos) then return "backward" end
	if M.cmp(pos, s) then return "forward" end
	return "upward"
end

function M.cmp_gen(cb)
	return function(a, b) return M.cmp(cb(a), cb(b)) end
end

--- ordering for upward axis
M.cmp_upwards = M.cmp_gen(
	function(a) return { a[1][1], a[1][2], -a[2][1], -a[2][2] } end
)

--- ordering for backward axis
M.cmp_backwards = M.cmp_gen(
	function(a) return { -a[2][1], -a[2][2], -a[1][1], -a[1][2] } end
)

--- ordering for forward axis
M.cmp_forwards = M.cmp_gen(
	function(a) return { a[1][1], a[1][2], a[2][1], a[2][2] } end
)

local function ripairs(s, i)
	i = i - 1
	if i > 0 then return i, s[i] end
end

--- reversed ipairs
---@param t table list
function M.ripairs(t) return ripairs, t, #t + 1 end

return M

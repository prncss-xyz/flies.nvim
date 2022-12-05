local M = {}

function M.from_list_single(list)
	local i = 0
	return function()
		i = i + 1
		return list[i]
	end
end

function M.to_list_single(gen, param, state)
	local list = {}
	local i = 1
	while true do
		state = gen(param, state)
		if state == nil then return list end
		list[i] = state
		i = i + 1
	end
end

function M.from_list_many(list)
	local i = 0
	return function()
		i = i + 1
		if list[i] then return unpack(list[i]) end
	end
end

function M.to_list_many(gen, param, state)
	local list = {}
	local i = 1
	while true do
		local values = { gen(param, state) }
		state = values[1]
		if state == nil then return list end
		list[i] = values
		i = i + 1
	end
end

function M.null()
	return function() end
end

function M.unit(...)
	local res = { ... }
	local once = true
	return function()
		if once then
			once = false
			return unpack(res)
		end
	end
end

function M.nth(i)
	return function(gen, param, state)
		while true do
			if i < 1 then return end
			if i < 2 then return gen(param, state) end
			state = gen(param, state)
			if state == nil then return end
			i = i - 1
		end
	end
end

function M.min(cmp)
	return function(gen, param, state)
		local res
		while true do
			local v = { gen(param, state) }
			param = v[1]
			if v == nil then break end
			if not res or cmp(v, res) == -1 then res = v end
		end
		return res
	end
end

return M

local M = {}

---@alias target {s?: integer[], e?: integer[], match: match}

--- select amonts target by hinting, call a funciton with result
---@param targets {s?: integer[], e?: integer[], match: match}[]
---@param cb fun(match: match)
function M.hint(targets, cb)
	if not targets then return end
	local jump_targets = {}
	local indirect_jump_targets = {}
	for i, hint in ipairs(targets) do
		local point = hint.s or hint.e
		if point then
			jump_targets[i] = {
				line = point[1] - 1,
				column = point[2],
				window = 0,
				object = hint.match,
			}
			indirect_jump_targets[i] = {
				index = i,
				score = i,
			}
		end
	end
	require("hop").hint_with_callback(
		function()
			return {
				jump_targets = jump_targets,
				indirect_jump_targets = indirect_jump_targets,
			}
		end,
		require("hop").opts,
		function(jump_target) cb(jump_target.object) end
	)
end

return M

local M = {}

function M.hint(hints, cb)
	if not hints then return end
	local jump_targets = {}
	local indirect_jump_targets = {}
	for i, hint in ipairs(hints) do
		local point = hint.s or hint.e
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
	require("hop").hint_with_callback(
		function()
			return {
				jump_targets = jump_targets,
				indirect_jump_targets = indirect_jump_targets,
			}
		end,
		require("hop").opts,
		function(jump_target)
			cb(jump_target.object)
		end
	)
end

return M

local M = require("flies2.operations._op"):new {}

local buffers = require "flies2.utils.buffers"
local editor = require "flies2.utils.editor"

function M:run(params)
	local match = params.match
	local wiseness = params.target:get_wiseness(0, match.outer)
	buffers.subs(0, match.outer, match.inner, wiseness, "", "", editor.indent)
end

return M

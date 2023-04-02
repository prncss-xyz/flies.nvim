local M = require("flies.operations._op"):new {}

local sandwich = require("flies.utils.sandwich").sandwich

function M:run(params) sandwich(self, params, false, true) end

function M.exec(mode)
	if mode == "n" then M:normal { domain = "outer", around = "never" } end
end

return M

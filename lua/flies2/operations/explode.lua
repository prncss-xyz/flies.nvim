local M = require("flies2.operations._op"):new {}

local sandwich = require("flies2.utils.sandwich").sandwich

function M:run(params) sandwich(self, params, false, true) end

function M.exec(mode)
	if mode == "n" then M:normal { domain = "outer", around = "never" } end
end

return M

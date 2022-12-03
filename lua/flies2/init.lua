local M = {}

local tables = require("flies2.utils.tables")

M.config = {}
function M.setup(user_config)
	tables.deep_merge(M.config, user_config or {})
end

return M

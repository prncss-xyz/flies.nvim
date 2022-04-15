local M = {}

function M.new()
  return setmetatable({}, { __index = M })
end

local name = require('flies.utils').name

-- M:texobject_domain_qualifier(mode)
-- M:texobject_domain_np(qualifier, mode)
-- M:move(domain, qualifier, start, mode)

return M

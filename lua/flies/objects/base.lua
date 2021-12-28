local M = {}

function M.new()
  return setmetatable({}, { __index = M })
end

-- texobject_domain_qualifier(self, mode)
-- move_domain_qualifier(self, start, mode)

return M

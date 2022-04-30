local M = {}

function M.new()
  return setmetatable({}, { __index = M })
end

--[[
function M:move(domain, qualifier, start, mode) end
function M:texobject_domain_qualifier(mode) end
function M:texobject_domain_np(qualifier, mode) end
]]

return M

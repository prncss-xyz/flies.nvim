local M = require('flies.objects.subline').new {}

local variable_segment_seek0_cb = M.any(
  M.lua_pattern '()%u+()$',
  M.lua_pattern '()%u+()(%W)',
  M.lua_pattern '()%u+()(%u%S)',
  M.lua_pattern '()%u?%l+(_?)'
)

function M.seek_cb(line, init)
  local os, is, ie, oe = variable_segment_seek0_cb(line, init)
  if not os then
    return
  end
  local c = string.sub(line, os - 1, os - 1)
  local d = string.sub(line, oe + 1, oe + 1)
  if (c == '_') and (d == '' or string.find(d, '[%A]')) then
    os = os - 1
  end
  return os, is, ie, oe
end

M.name = 'variable_segment'
M.blank_text_object = true

return M

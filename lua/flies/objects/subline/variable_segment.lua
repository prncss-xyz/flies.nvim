local M = require('flies.objects.subline'):new {
  name = 'variable_segment',
  blank_text_object = true,
}

local variable_segment_seek0_cb = M.any(
  M.lua_pattern '()%u+()$',
  M.lua_pattern '()%u+()(%W)',
  M.lua_pattern '()%u+()(%u%S)',
  M.lua_pattern '()%u?[%l%d]+(_?)'
)

local function seek_cb(line, init)
  local os, is, ie, oe = variable_segment_seek0_cb(line, init)
  if not os then
    return
  end
  local c = string.sub(line, os - 1, os - 1)
  local d = string.sub(line, oe, oe)
  local e = string.sub(line, oe + 1, oe + 1)
  if (c == '' or c:find '[^%w_]') and (e == '' or e:find '[^%w_]') then
    return M.seek_cb(line, oe + 1)
  end
  if (c == '_') and (d ~= '_') and (e == '' or string.find(e, '[^%w_]')) then
    os = os - 1
  end
  return os, is, ie, oe
end

M.seek_cb = M.any(
  seek_cb,
  M.lua_pattern '()_+()'
)

return M

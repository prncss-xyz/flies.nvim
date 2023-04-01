local M = {}

M.section = [[
  (section (section (atx_heading) @inner.before) @outer @inner.end) @context
  (section (atx_heading (atx_h1_marker)) @inner.before) @inner.end @outer
]]

return M

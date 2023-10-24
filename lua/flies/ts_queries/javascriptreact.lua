local M = {}

M.argument = [[
  ;; query
  (jsx_opening_element name: (identifier) @context.before attribute: (jsx_attribute ((property_identifier) @key)? (_) @inner) @outer ">" @context.after)
  (jsx_self_closing_element name: (identifier) @context.before attribute: (jsx_attribute ((property_identifier) @key)? (_) @inner) @outer "/>" @context.after)
]]

M.tag = [[
  ;; query
  (jsx_element) @outer @inner.inside
  (jsx_self_closing_element) @outer
]]

M.open_close = [[
  ;; query
  ; tag
  ;; open
  (jsx_self_closing_element . (_) @tag_open ) @outer
  ;; close
  (jsx_element (jsx_opening_element . (_) @tag_close (_)*) @element (_)* @protect (jsx_closing_element) ) @outer
]]

return M

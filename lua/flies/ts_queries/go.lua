local M = {}

-- TODO: struct, table

M.argument = [[
  ;; query
  (parameter_list (_) @outer) @context.inside
  (argument_list (_) @outer) @context.inside
  (literal_value (literal_element) @outer) @context.inside
]]

M.block = [[
  ;; query
  (block) @outer @inner.inside
]]

M.call = [[
  ;; query
  (call_expression arguments: (_) @inner.inside) @outer
]]

M.comment = [[
  ;; query
  (comment) @outer @inner.inside
]]

M.conditional = [[
  ;; query
  (if_statement condition: _ @inner) @outer 
]]

M["function"] = [[
  ;; query
  (function_declaration body: (_) @inner.inside) @outer
]]

M.loop = [[
  ;; query
  (for_statement (for_clause) @inner) @outer
]]

M.string = [[
  ;; query
  (interpreted_string_literal) @inner.inside @outer
]]

return M

local M = {}

-- TODO: struct, table
M.argument = [[
  (parameter_list (_) @outer) @context.node_inside
  (argument_list (_) @outer) @context.node_inside
  (literal_value (literal_element) @outer) @context.node_inside
]]

M.block = [[
  (block) @outer @inner.node_inside

]]

M.call = [[
  (call_expression arguments: (_) @inner.node_inside) @outer
]]

M.comment = [[
  (comment) @outer @inner.1node
]]

M.conditional = [[
  (if_statement condition: _ @inner) @outer 
]]

M["function"] = [[
  (function_declaration body: (_) @inner.node_inside) @outer
]]

M.loop = [[
  (for_statement (for_clause) @inner) @outer
]]

M.string = [[
  (interpreted_string_literal) @inner.node_inside @outer
]]

return M

local M = {}

-- .inside1 .1node .node_inside
-- .before
-- .after

M.argument = [[
  (function_call arguments: (arguments (_) @outer)) @context.node_inside
  (function_declaration parameters: (parameters (_) @outer)) @context.node_inside
  (table_constructor (field name: (identifier)? @key value: (_) @inner) @outer) @context.node_inside
  (variable_list name: (_) @outer) @context.node_inside

  ; we exclude lists of length one for pratical raisons
  (expression_list value: (_) @outer (_)) @context
  (expression_list value: (_) (_) @outer) @context
  (variable_list name: (identifier) @outer (identifier)) @context
  (variable_list name: (identifier) (identifier) @outer) @context
]]

-- TODO: ?? empty block
M.block = [[
  (_ (block) @inner) @outer
]]

M.call = [[
  (function_call arguments: (arguments "(") @inner.node_inside) @outer
  (function_call arguments: (arguments [(table_constructor) (string)]) @inner) @outer
]]

M.comment = [[
  (comment) @outer @inner.1node
]]

M.conditional = [[
  (if_statement "then" @inner.before "end" @inner.after) @outer
  (function_definition parameters: (_) @inner.before "end" @inner.after) @outer
]]

M["function"] = [[ 
  (function_declaration parameters: (_) @inner.before "end" @inner.after) @outer
  (function_definition parameters: (_) @inner.before "end" @inner.after) @outer
]]

M.loop = [[
  (repeat_statement "repeat" @inner.before "until" @inner.after) @outer
  (for_statement "do" @inner.before "end" @inner.after) @outer
  (while_statement "do" @inner.before "end" @inner.after) @outer
]]

M.string = [[
  (string) @outer @inner.1node
]]

return M

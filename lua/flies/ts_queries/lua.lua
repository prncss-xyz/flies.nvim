local M = {}

-- .inside1 .1node .node_inside
-- .before
-- .after

M.token = [[
  ;; query
  (_) @outer
]]

M.argument = [[
  ;; query
  (function_call arguments: (arguments (_) @outer) @context.node_inside)
  (function_declaration parameters: (parameters (_) @outer) @context.node_inside)
  (function_declaration parameters: (parameters (_) @outer) @context.node_inside)
  (table_constructor (field name: (identifier)? @key value: (_) @inner) @outer) @context.node_inside

  ; we exclude lists of length one for pratical raisons

  (expression_list value: (_) @outer (_)) @context
  (expression_list value: (_) (_) @outer) @context
  (variable_list name: (_) @outer) @context
  (variable_list name: (identifier) @outer (identifier)) @context
  (variable_list name: (identifier) (identifier) @outer) @context
]]

-- TODO: ?? empty block
M.block = [[
  ;; query
  (_ (block) @inner) @outer
]]

M.call = [[
  ;; query
  (function_call arguments: (arguments "(") @inner.node_inside) @outer
  (function_call arguments: (arguments [(table_constructor) (string)]) @inner) @outer
]]

M.comment = [[
  ;; query
  (comment) @outer @inner.1node
]]

M.conditional = [[
  ;; query
  (if_statement consequence:(block) @outer) @context
  (if_statement alternative:(elseif_statement consequence:(block) @outer)) @context
  (if_statement alternative:(else_statement body:(block) @outer)) @context
]]

M["function"] = [[
  ;; query
  (function_declaration parameters: (_) @inner.before "end" @inner.after) @outer
  (function_definition parameters: (_) @inner.before "end" @inner.after) @outer
]]

M.loop = [[
  ;; query
  (repeat_statement "repeat" @inner.before "until" @inner.after) @outer
  (for_statement "do" @inner.before "end" @inner.after) @outer
  (while_statement "do" @inner.before "end" @inner.after) @outer
]]

M.string = [[
  ;; query
  (string) @outer @inner.1node
]]

return M

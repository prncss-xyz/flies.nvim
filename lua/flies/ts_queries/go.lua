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

M.delimiter = [[
  ;; query
  (parenthesized_expression "(" @inner.before ")" @inner.after) @outer
  (import_spec_list "(" @inner.before ")" @inner.after) @outer
  (var_spec_list "(" @inner.before ")" @inner.after) @outer
  (const_declaration "(" @inner.before ")" @inner.after) @outer
  (type_assertion_expression "(" @inner.before ")" @inner.after) @outer
  (argument_list "(" @inner.before ")" @inner.after) @outer
  (parameter_list "(" @inner.before ")" @inner.after) @outer
  (field_declaration_list "{" @inner.before "}" @inner.after) @outer
  (block "{" @inner.before "}" @inner.after) @outer
  (expression_switch_statement "{" @inner.before "}" @inner.after) @outer
  (type_switch_statement "{" @inner.before "}" @inner.after) @outer
  (literal_value "{" @inner.before "}" @inner.after) @outer
  (interface_type "{" @inner.before "}" @inner.after) @outer
  (array_type "[" @inner.before "]" @inner.after) @outer
  (slice_type "[" @inner.before "]" @inner.after) @outer
  (map_type "[" @inner.before "]" @inner.after) @outer
  (type_parameter_list "[" @inner.before "]" @inner.after) @outer
  (type_arguments "[" @inner.before "]" @inner.after) @outer
  (index_expression "[" @inner.before "]" @inner.after) @outer
  (slice_expression "[" @inner.before "]" @inner.after) @outer
]]

return M

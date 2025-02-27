local M = {}

M.argument = [[
  ;; query
  (formal_parameters ((_) @outer)) @context.inside
  (arguments ((_) @outer)) @context.inside
  (array ((_) @outer)) @context.inside
  (array_pattern ((_) @outer)) @context.inside
  (object ((pair key:(_)@key value:(_)@inner) @outer)) @context.inside
  (object_pattern (pair_pattern key:(_) @key value: (_) @inner) @outer) @context.inside
  (object_pattern (shorthand_property_identifier_pattern) @outer) @context.inside
  (named_imports ((import_specifier name: (identifier) @key alias: (identifier)? @inner) @outer)) @context.inside
]]

M.block = [[
  ;; query
  (export_statement) @outer @inner.inside
  (import_statement) @outer @inner.inside
  (function_declaration) @outer @inner.inside
  (statement_block) @outer @inner.inside
  (return_statement) @outer @inner.inside

  ; (_ (statement_block) @inner.inside) @outer
]]

M.call = [[
  ;; query
  (call_expression arguments: (arguments) @inner.inside) @outer
]]

M.class = [[
  ;; query
  (class_declaration body: (class_body) @inner.inside) @outer
  (export_statement (class_declaration body: (class_body) @inner.inside)) @outer

  (class body: (class_body) @inner.inside) @outer
  (lexical_declaration (variable_declarator value: (class body: (class_body) @inner.inside))) @outer
  (export_statement (lexical_declaration (variable_declarator value: (class body: (class_body) @inner.inside)))) @outer
]]

M.comment = [[
  ;; query
  ((comment) @inner.inside @outer)
]]

M.conditional = [[
  ;; query
  (if_statement condition: _ @inner.before) @outer
  (switch_statement body: (switch_body)@inner.inside) @outer
]]

M["function"] = [[
  ;; query
  (method_definition body: (_)@inner.inside) @outer
  (function_declaration body: (_)@inner.inside) @outer
  (arrow_function body: (statement_block)@inner.inside) @outer
  (arrow_function body: [
    (undefined)
    (null)
    (false)
    (true)
    (number)
    (string)
    (array)
    (identifier)
    (binary_expression)
    (call_expression)
    (parenthesized_expression)
  ]@inner) @outer
]]

M.loop = [[
  ;; query
  (while_statement body: (_)@inner) @outer
  (do_statement body: (_)@inner) @outer
  (for_statement body: (_)@inner) @outer
  (for_in_statement body: (_)@inner) @outer
]]

-- regex syntax prevents empty patterns
M.regex = [[
  ;; query
  (regex (regex_pattern) @regex.inner) @regex.outer
]]

M.string = [[
  ;; query
  [(string) (template_string)] @inner.inside @outer
]]

M.open_close = [[
  ;; query

  ; arrow
  ;; open
  (arrow_function body: [
    (undefined)
    (null)
    (false)
    (true)
    (number)
    (string)
    (array)
    (identifier)
    (binary_expression)
    (call_expression)
    (parenthesized_expression)
  ] @arrow_open) @outer
  ;; close
  (arrow_function body: (statement_block ((_)? @protect (return_statement (_) @arrow_close)) ) @outer)
]]

return M

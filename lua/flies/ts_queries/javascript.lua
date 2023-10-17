local M = {}

M.argument = [[
  ;; query
  (formal_parameters ((_) @outer)) @context.node_inside
  (arguments ((_) @outer)) @context.node_inside
  (array ((_) @outer)) @context.node_inside
  (array_pattern ((_) @outer)) @context.node_inside
  (object ((pair key:(_)@key value:(_)@inner) @outer)) @context.node_inside
  (object_pattern (pair_pattern key:(_) @key value: (_) @inner) @outer) @context.node_inside
  (object_pattern (shorthand_property_identifier_pattern) @outer) @context.node_inside
  (named_imports ((import_specifier name: (identifier) @key alias: (identifier)? @inner) @outer)) @context.node_inside
]]

M.block = [[
  ;; query
  (export_statement) @outer @inner.node_inside
  (import_statement) @outer @inner.node_inside
  (function_declaration) @outer @inner.node_inside
  (statement_block) @outer @inner.node_inside
  (return_statement) @outer @inner.node_inside

  ; (_ (statement_block) @inner.node_inside) @outer
]]

M.call = [[
  ;; query
  (call_expression arguments: (arguments) @inner.node_inside) @outer
]]

M.class = [[
  ;; query
  (class_declaration body: (class_body) @inner.node_inside) @outer
  (export_statement (class_declaration body: (class_body) @inner.node_inside)) @outer

  (class body: (class_body) @inner.node_inside) @outer
  (lexical_declaration (variable_declarator value: (class body: (class_body) @inner.node_inside))) @outer
  (export_statement (lexical_declaration (variable_declarator value: (class body: (class_body) @inner.node_inside)))) @outer
]]

M.comment = [[
  ;; query
  ((comment) @inner.node_second  (#lua-match? @inner.node_second "^//"))
  ((comment) @inner.node_second  (#lua-match? @inner.node_inside "^/*"))
]]

M.conditional = [[
  ;; query
  (if_statement condition: _ @inner.before) @outer
  (switch_statement body: (switch_body)@inner.node_inside) @outer
]]

M["function"] = [[
  ;; query
  (method_definition body: (_)@inner.node_inside) @outer
  (function_declaration body: (_)@inner.node_inside) @outer
  (function body: (_)@inner.node_inside) @outer
  (arrow_function body: (statement_block)@inner.node_inside) @outer
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
  [(string) (template_string)] @inner.node_inside @outer
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

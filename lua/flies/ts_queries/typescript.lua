local M = {}

M.argument = [[
  ;; query
  (object_type (property_signature) @outer.start ";" @outer.end) @context.inside
  (object_type (index_signature name:_ @key type: (type_annotation (_) @inner)) @outer) @context.inside
  (tuple_type (_) @inner) @context.inside
]]

M.delimiter = [[
  ;; query
  (interface_body "{" @inner.before "}" @inner.after) @outer
  (enum_body "{" @inner.before "}" @inner.after) @outer
  (object_type "{" @inner.before "}" @inner.after) @outer
  (type_arguments "<" @inner.before ">" @inner.after) @outer
  (type_parameters "<" @inner.before ">" @inner.after) @outer
  (array_type "[" @inner.before "]" @inner.after) @outer
  (lookup_type "[" @inner.before "]" @inner.after) @outer
  (tuple_type "[" @inner.before "]" @inner.after) @outer
]]

return M

local M = {}

M.argument = [[
  ;; query
  (object_type (property_signature) @outer.start ";" @outer.end) @context.inside
  (object_type (index_signature name:_ @key type: (type_annotation (_) @inner)) @outer) @context.inside
  (tuple_type (_) @inner) @context.inside
]]

return M

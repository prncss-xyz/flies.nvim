local M = {}

M.argument = [[
  ; ts
  (object_type (property_signature) @outer.start ";" @outer.end) @context.node_inside
  (object_type (index_signature name:_ @key type: (type_annotation (_) @inner)) @outer) @context.node_inside
  (tuple_type (_) @inner) @context.node_inside
]]

return M

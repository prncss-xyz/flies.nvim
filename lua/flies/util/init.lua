local M = {}

local get_path = require('flies.utils').get_path

function M.get_opts(opts, query, name)
  return vim.tbl_extend(
    'force',
    get_path(require 'flies', 'conf', 'actions', name) or {},
    get_path(query, 'actions', name) or {},
    opts or {}
  )
end

return M

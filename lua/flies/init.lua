local M = {}

local default_conf = {
  qualifiers = {
    p = 'previous',
    n = 'next',
    h = 'hint',
  },
  domains = {
    i = 'inner',
    a = 'outer',
  },
}

local t = require('flies.utils').t

function M.textobject(query_map, domain, qualifier, mode)
  local query = M.queries[t(query_map)]
  if not query then
    return
  end
  query.textobject(query, domain, qualifier)
end

local function map_texobjects()
  for domain_map, domain in pairs(M.domains) do
    for qualifier_map, qualifier in pairs(M.qualifiers) do
      for query_map, query in pairs(M.queries) do
        local query_name = query.name
        local desc = string.format(
          'textobj %s %s %s',
          query_name,
          domain,
          qualifier
        )
        vim.keymap.set('o', domain_map .. qualifier_map .. query_map, function()
          M.textobject(query_map, domain, qualifier, 'o')
        end, { desc = desc })
        vim.api.nvim_set_keymap(
          'x',
          domain_map .. qualifier_map .. query_map,
          string.format(
            ':<c-u>lua require"flies".textobject(%q, %q, %q, "x")<cr>',
            query_map,
            domain,
            qualifier
          ),
          {}
        )
      end
    end
  end
end

function M.setup(user_conf)
  local conf = vim.tbl_extend('force', default_conf, user_conf or {})
  require('flies.repeater').setup()
  M.domains = conf.domains
  local queries = {}
  for k, v in pairs(conf.queries) do
    local c = t(k)
    queries[c] = v
    v.char = c
  end
  M.queries = queries
  local qualifiers = {}
  local plain = false
  for k, v in pairs(conf.qualifiers) do
    local c = t(k)
    qualifiers[c] = v
    if v == 'plain' then
      plain = true
    end
  end
  if not plain then
    -- HACK: not good: why those two?
    qualifiers[''] = 'plain'
  end
  M.qualifiers = qualifiers
  map_texobjects()
  -- map_move()

  M.repeater = require 'flies.repeater'
  M.operations_register = require('flies.operations.base').reg
  require 'flies.operations.init'
end

return M

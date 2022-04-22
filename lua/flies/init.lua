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
local name = require('flies.utils').name

function M.is_textobject(query_map, domain, qualifier)
  local query = M.queries[t(query_map)]
  if not query then
    return
  end
  if qualifier == 'next' or qualifier == 'previous' then
    return query[name('textobject', domain, 'np')]
  else
    return query[name('textobject', domain, qualifier)]
  end
end

function M.textobject(query_map, domain, qualifier, mode)
  local query = M.queries[t(query_map)]
  if not query then
    return
  end
  if qualifier == 'next' or qualifier == 'previous' then
    query[name('textobject', domain, 'np')](query, qualifier, mode)
  else
    query[name('textobject', domain, qualifier)](query, mode)
  end
end

local function map_texobjects()
  for domain_map, domain in pairs(M.domains) do
    for mode in string.gmatch('ox', '.') do
      for qualifier_map, qualifier in pairs(M.qualifiers) do
        for query_map, query in pairs(M.queries) do
          if M.is_textobject(query_map, domain, qualifier) then
            local query_name = query.name
            local desc = string.format(
              'textobj %s %s %s',
              query_name,
              domain,
              qualifier
            )
            vim.keymap.set(
              mode,
              domain_map .. qualifier_map .. query_map,
              function()
                M.textobject(query_map, domain, qualifier, mode)
              end,
              { desc = desc }
            )
          end
        end
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
end

return M

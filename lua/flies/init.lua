local M = {}

local default_conf = {
  dot = '.',
}
local conf
local queries
local qualifiers

local t = require('flies.utils').t

local rep = {
  previous = function(_) end,
  next = function(_) end,
}

function M.repeatable(previous, next)
  local fp = function()
    M.repeat_register(previous, next)
    previous()
  end
  local fn = function()
    M.repeat_register(previous, next)
    next()
  end
  return fp, fn
end

function M.repeat_register(previous, next)
  rep.previous = previous
  rep.next = next
end

function M.repeat_previous(mode)
  if rep.previous then
    rep.previous(mode)
  end
end

function M.repeat_next(mode)
  if rep.next then
    rep.next(mode)
  end
end

function M.textobject(command_name, query_map, mode)
  local query = queries[t(query_map)]
  query[command_name](query, mode)
end

local function jump(target, backward, till, n_times)
  local flags = backward and 'Wb' or 'W'
  if till then
    if backward then
      target = target .. '.'
    else
      target = '.' .. target
    end
  end
  if backward and till then
    flags = flags .. 'e'
  end

  for _ = 1, n_times do
    vim.fn.search(target, flags)
  end

  -- Open enough folds to show jump
  vim.cmd 'normal! zv'
end

function M.move(query_char, qualifier, domain, start, mode)
  local name = require('flies.utils').name
  local query = queries[query_char]
  if query then
    local command_name = name('move', domain, qualifier)
    if query[command_name] then
      query[command_name](query, start, mode)
      return
    end
    domain = domain == 'inner' and 'outer' or 'inner'
    command_name = name('move', domain, qualifier)
    if query[command_name] then
      query[command_name](query, start, mode)
      return
    end
    return
  end
  jump(
    '[' .. query_char .. ']',
    qualifier == 'previous',
    domain == 'inner',
    vim.v.count1
  )
end

function M.init_move(query_char, qualifier, domain, start, mode)
  local name = require('flies.utils').name
  local query = queries[query_char]
  if query then
    local command_name = name('init_move', domain, qualifier)
    if query[command_name] then
      query[command_name](query, start, mode)
      return
    end
  end
  M.move(query_char, qualifier, domain, start, mode)
end

local function query_obj0()
  local qualifier
  local qualifier_char
  while true do
    local char = vim.fn.getchar()
    char = vim.fn.nr2char(char)
    local r = M.qualifiers[char]
    if r then
      if qualifier then
        return
      end
      qualifier = r
      qualifier_char = char
    elseif char == t '<esc>' then
      return
    else
      return {
        query = M.queries[char],
        query_char = char,
        qualifier = qualifier or 'plain',
        qualifiers_char = qualifier_char,
      }
    end
  end
end

function M.query_obj()
  return require('flies.repeater').querier(query_obj0)
end

-- TODO: reusable: accept a callback to set parameters
-- TODO: make repeatable
-- TODO: escape hatch
function M.meta_move(mode)
  local q = M.query_obj()
  if not q then
    return
  end
  local qualifier = q.qualifier
  local char = q.query_char
  local query_o = q.query
  if qualifier == 'plain' then
    qualifier = 'next'
  end
  local domain
  if mode == 'n' then
    domain = 'outer'
  elseif query_o then
    domain = 'inner'
  else
    domain = 'outer'
  end
  -- TODO: 'instance of'
  if query_o and query_o:name() == 'line' then
    domain = 'inner'
  end
  local start = (qualifier == 'previous')
  if mode == 'n' and query_o and not query_o.normal_dir then
    start = true
  end
  if mode == 'o' and qualifier == 'next' then
    vim.cmd 'normal! v'
  end
  -- print(
  --   query_o and query_o:name() or string.format('%q', char),
  --   qualifier,
  --   domain,
  --   start,
  --   mode
  -- )
  M.repeat_register(function(mode0)
    M.move(char, 'previous', domain, start, mode0)
  end, function(mode0)
    M.move(char, 'next', domain, start, mode0)
  end)
  M.init_move(char, qualifier, domain, start, mode)
end

function M.append_insert()
  local q = require('flies.repeater').query_obj()
  if not q then
    return
  end
  local qualifier = q.qualifier
  local char = q.query_char
  local query_o = q.query
  if qualifier == 'plain' then
    qualifier = 'next'
  end
  local domain = query_o and 'inner' or 'outer'
  M.move(char, qualifier, domain, qualifier == 'previous', 'n')
  -- TODO: linewiseness
  -- TODO: one space padding ??
  -- TODO: escape hatch
  if not query_o then
    vim.api.nvim_feedkeys('a', 'n', false)
  else
    if query_o.blank_text_object then
      if qualifier == 'previous' then
        vim.api.nvim_feedkeys('hi', 'n', false)
      else
        vim.api.nvim_feedkeys('a', 'n', false)
      end
    else
      if qualifier == 'next' then
        vim.api.nvim_feedkeys('a', 'n', false)
      else
        vim.api.nvim_feedkeys('hi', 'n', false)
        -- vim.cmd 'normal! h'
      end
    end
  end
end

local function map_texobjects()
  local name = require('flies.utils').name
  for domain_map, domain in pairs(conf.domains) do
    for mode in string.gmatch('ox', '.') do
      for qualifier_map, qualifier in pairs(conf.qualifiers) do
        for query_map, query in pairs(conf.queries) do
          local command_name = name('textobject', domain, qualifier)
          if query[command_name] then
            vim.api.nvim_set_keymap(
              mode,
              domain_map .. qualifier_map .. query_map,
              string.format(
                ':lua require("flies").textobject(%q, %q, %q)<cr>',
                command_name,
                t(query_map),
                mode
              ),
              { noremap = true }
            )
          end
        end
      end
    end
  end
end

function M.setup(user_conf)
  conf = vim.tbl_extend('force', default_conf, user_conf or {})
  require('flies.repeater').setup()

  queries = {}
  for k, v in pairs(conf.queries) do
    local c = t(k)
    queries[c] = v
    v.char = c
  end
  M.queries = queries
  qualifiers = {}
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
    conf.qualifiers[''] = 'plain'
  end
  M.qualifiers = qualifiers
  map_texobjects()
  -- map_move()
end

return M

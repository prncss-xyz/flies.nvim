local M = {}

local repeater = require 'flies.repeater'
local query_obj = require('flies.utils').query_obj

local t = require('flies.utils').t

function M.move(mode, opts)
  repeater.init()
  local q = repeater.querier(query_obj)
  if not q then
    return
  end
  local query_o = q.query
  local qualifier = q.qualifier
  opts = require('flies.util').get_opts(opts, query_o, 'move')
  local domain = opts.domain
  if domain then
  elseif qualifier == 'next' then
    domain = 'inner'
  elseif query_o.blank_text_object then
    domain = 'inner'
  elseif mode == 'n' then
    domain = 'outer'
  else
    domain = 'inner'
  end
  if qualifier == 'plain' then
    qualifier = 'next'
  end
  if mode == 'o' and qualifier == 'next' then
    vim.cmd 'normal! v'
  end
  local start = opts.start
  if start == nil then
    start = true
  end
  if mode == 'n' then
    require('flies.move_again').register(function()
      query_o:motion(domain, 'previous', start, vim.v.count1)
    end, function()
      query_o:motion(domain, 'next', start, vim.v.count1)
    end)
  end
  query_o:motion(domain, qualifier, start, vim.v.count1)
end

function M.append_insert()
  repeater.init()
  local q = repeater.querier(query_obj)
  if not q then
    return
  end
  local qualifier = q.qualifier
  if qualifier == 'plain' then
    qualifier = 'next'
  end
  local query_o = q.query
  query_o:search_cb(
    'inner',
    'plain',
    require('flies.utils').get_cursor(),
    vim.v.count1,
    function(s, e, w)
      local pos = qualifier == 'next' and e or s
      require('flies.utils').set_cursor(pos)
      local cmd_char = qualifier == 'previous' and 'i' or 'a'
      if w == 'V' then
        cmd_char = cmd_char:upper()
      end
      vim.api.nvim_feedkeys(cmd_char, 'n', false)
    end
  )
end

local utils = require 'flies.utils'
local cmp = require('flies.objects.utils').cmp

function M.extremity()
  repeater.init()
  local q = repeater.querier(query_obj)
  if not q then
    return
  end
  local qualifier = q.qualifier
  local query_o = q.query
  local domain
  if qualifier == 'next' or query_o.blank_text_object then
    domain = 'inner'
  else
    domain = 'outer'
  end
  query_o:search_cb(
    domain,
    'plain',
    require('flies.utils').get_cursor(),
    1,
    function(s, e, w)
      -- FIXME: should be order 2 after applying once; cf treesitter objects
      if w == 'V' then
        local row = require('flies.objects.utils').get_row(e[1])
        e[2] = require('flies.objects.utils').line_inner_start(row)
      end
      local cursor = require('flies.utils').get_cursor()
      local pos
      if qualifier == 'previous' then
        pos = s
      else
        pos = e
      end
      if w == 'V' then
        if cursor[1] == s[1] then
          pos = e
        elseif cursor[1] == e[1] then
          pos = s
        end
      else
        if cmp(cursor, s) == 0 then
          pos = e
        elseif cmp(cursor, e) == 0 then
          pos = s
        end
      end
      utils.set_cursor(pos)
    end
  )
end

--- wrapper for vim operators
function M.op(op, opts)
  repeater.init()
  local q = repeater.querier(query_obj)
  if not q then
    return
  end
  opts = require('flies.util').get_opts(opts, q.query)
  local domain = opts.domain or 'outer'
  local noremap = opts.noremap
  if noremap == nil then
    noremap = true
  end
  vim.api.nvim_feedkeys(t(op), noremap and 'n' or 'm', true)
  local str = string.format(
    ':<c-u>lua require"flies".textobject(%q, %q, %q)<cr>',
    q.query_char,
    domain,
    q.qualifier
  )
  vim.api.nvim_feedkeys(t(str), 'n', true)
end

function M.bind_op(op, opts, name)
  local noremap = opts.noremap
  if noremap == nil then
    noremap = true
  end
  vim.api.nvim_set_keymap('n', string.format('<Plug>(%s)', name), function()
    M.op(op, opts)
  end, {})
  vim.api.nvim_set_keymap(
    'x',
    string.format('<Plug>(%s)', name),
    op,
    { noremap = noremap }
  )
end

return M

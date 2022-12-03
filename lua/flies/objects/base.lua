local M = require('flies.util.object'):new()

local iter = require 'flies.util.iterator'
local cmp = require('flies.objects.utils').cmp

-- local function search_forward(init, count) end
-- local function search_backward(init, count) end
-- selection_mode, os, is, ie, oe

function M:search_forward(domain, pos, count)
  local s, e, w
  s, e, w = iter.nth(count)(self:np_iterator(domain, pos, true, true))
  return s, e, w
end

function M:search_backward(domain, pos, count)
  local s, e, w
  s, e, w = iter.nth(count)(self:np_iterator(domain, pos, false, false))
  return s, e, w
end

function M:search_plain(domain, init, count)
  if self.up_cb then
    local s, e, w = self:up_cb(domain, init, count)
    if s then
      return s, e, w
    end
  elseif self.up_iterator then
    local s, e, w
    if count == 'last' then
      s, e, w = iter.last(self:up_iterator(domain, init))
    else
      s, e, w = iter.nth(count)(self:up_iterator(domain, init))
    end
    if s then
      return s, e, w
    end
  end
  return self:search_forward(domain, init, count)
end

function M:search(domain, qualifier, init, count)
  if qualifier == 'plain' then
    return self:search_plain(domain, init, count)
  end
  if qualifier == 'next' then
    return self:search_forward(domain, init, count)
  end
  if qualifier == 'previous' then
    return self:search_backward(domain, init, count)
  end
  if qualifier == 'hint' then
    assert(false, string.format('use search_cb with qualifier %q', qualifier))
  end
  assert(false, string.format('unknown qualifier %q', qualifier))
end

function M:search_cb(domain, qualifier, init, count, cb)
  if qualifier == 'hint' then
    self:hint(domain, cb)
    return
  end
  cb(self:search(domain, qualifier, init, count))
end

function M.select(s, e, w)
  if s then
    require('flies.objects.utils').update_selection(s, e, w)
  end
end

function M:textobject(domain, qualifier, mode)
  require('flies.repeater').init()
  local pos = require('flies.utils').get_cursor()
  local count = vim.v.count == 1 and 'last' or vim.v.count1
  self:search_cb(domain, qualifier, pos, count, M.select)
end

function M.jump(start)
  return function(s, e)
    local p
    if start then
      p = s
    else
      p = e
    end
    if not p then
      return
    end
    require('flies.utils').set_cursor(p)
  end
end

function M:move_cb(domain, qualifier, start, count, cb)
  if qualifier == 'hint' then
    self:hint(domain, cb)
    return
  end
  local cursor = require('flies.utils').get_cursor()
  local s, e
  s, e, w = iter.nth(count)(
    self:np_iterator(domain, cursor, qualifier == 'next', start)
  )
  if s then
    cb(start)(s, e, w)
  end
end

function M:motion(domain, qualifier, start, count)
  self:move_cb(domain, qualifier, start, count, M.jump)
end

function M:jump_target_gtr(domain)
  local manh_dist = require('hop.jump_target').manh_dist
  local context = require('hop.window').get_window_context()
  context = context[1].contexts[1]
  local start = context.top_line + 1
  local end_ = context.bot_line + 1
  local cursor_pos = context.cursor_pos
  local jump_targets = {}
  local indirect_jump_targets = {}
  local index = 0
  for s, e, w in self:np_iterator(domain, { start, 0 }, true, true, end_) do
    index = index + 1
    local line = s[1] - 1
    local column = s[2]
    table.insert(jump_targets, {
      line = line,
      column = column,
      window = 0,
      object = { s, e, w },
    })
    table.insert(indirect_jump_targets, {
      index = index,
      score = -manh_dist({ line, column }, cursor_pos),
    })
  end
  for _, target in ipairs(jump_targets) do
    local s, e = unpack(target.object)
    if cmp(s, cursor_pos) <= 0 and cmp(cursor_pos, e or s) <= 0 then
      -- dump(s, e)
    end
  end
  return {
    jump_targets = jump_targets,
    indirect_jump_targets = indirect_jump_targets,
  }
end

function M:hint(domain, cb)
  require('hop').hint_with_callback(
    function()
      return self:jump_target_gtr(domain)
    end,
    require('hop').opts,
    function(res)
      cb(unpack(res.object))
    end
  )
end

M.actions = {}

return M

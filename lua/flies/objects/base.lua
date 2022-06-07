local M = {}

local iter = require 'flies.util.iterator'

-- local function search_forward(init, count) end
-- local function search_backward(init, count) end
-- selection_mode, os, is, ie, oe

function M:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  return o
end

function M:super(method, ...)
  local mt = getmetatable(self).__index
  return mt[method](self, ...)
end

function M:search_forward(domain, pos, count)
  local s, e, w
  if count == 'last' then
    s, e, w = iter.last((self:np_iterator(domain, pos, true, true)))
  else
    s, e, w = iter.nth(count)(self:np_iterator(domain, pos, true, true))
  end
  return s, e, w
end

function M:search_backward(domain, pos, count)
  local s, e, w
  if count == 'last' then
    s, e, w = iter.last((self:np_iterator(domain, pos, false, false)))
  else
    s, e, w = iter.last((self:np_iterator(domain, pos, false, false)))
  end
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

function M.select(s, e)
  if s then
    require('flies.objects.utils').update_selection(s, e)
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

function M:motion(domain, qualifier, start)
  if qualifier == 'hint' then
    self:hint(domain, M.jump(start))
    return
  end
  local pos = require('flies.utils').get_cursor()
  local count = vim.v.count == 1 and 'last' or vim.v.count1
  local s, e
  if count == 'last' then
    s, e = iter.last(self:np_iterator(domain, pos, qualifier == 'next', start))
  else
    s, e = iter.nth(count)(
      self:np_iterator(domain, pos, qualifier == 'next', start)
    )
  end
  if s then
    M.jump(start)(s, e)
  end
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

return M

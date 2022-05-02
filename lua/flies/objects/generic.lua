local M = {}

-- local function search_forward(init, count) end
-- local function search_backward(init, count) end
-- selection_mode, os, is, ie, oe

function M.new()
  return setmetatable({}, { __index = M })
end

local function move_cursor(pos)
  pos[2] = pos[2] - 1
  vim.api.nvim_win_set_cursor(0, pos)
end

local function get_cursor()
  local init = vim.api.nvim_win_get_cursor(0)
  init[2] = init[2] + 1
  return init
end

function M:_search_upward_pp(domain, init, count)
  local s, e = self:search_upward(domain, init, count)
  if s then
    return self:post_proc(domain, s, e)
  end
end

function M:_search_forward_pp(domain, init, count)
  local s, e = self:search_forward(domain, init, count)
  if s then
    return self:post_proc(domain, s, e)
  end
end

function M:_search_backward_pp(domain, init, count)
  local s, e = self:search_backward(domain, init, count)
  if s then
    return self:post_proc(domain, s, e)
  end
end

if false then
  function M:default_search_iter(domain, init)
    local line, col = unpack(init)
    local function step()
      local s, e = self:search_forward(domain, { line, col }, 1)
      if not s then
        return
      end
      if M.no_nest then
        line, col = unpack(s)
      else
        line, col = unpack(e)
      end
      return s, e
    end
    return step, nil, true
  end

  function M:_search_range_pp_iter(domain, start, end_)
    local init = { start, 0 }
    local fn, state, s
    if self.search_iter then
      fn, state, s = self:search_iter(domain, init)
    else
      fn, state, s = self:default_search_iter(domain, init)
    end
    local e
    local oc, ol
    local function step()
      s, e = fn(state, s)
      assert(not (oc == s[1] and ol == s[2]), 'iterator not forwarding')
      oc, ol = unpack(s)
      if s[1] > end_ then
        return
      end
      if s then
        return self:post_proc(domain, s, e)
      end
    end
    return step, nil, true
  end
end

function M:move(domain, qualifier, start)
  if qualifier == 'hint' then
    self:hint(domain, move_cursor)
    return
  end
  local s, e, p
  local cmp = require('flies.objects.utils').cmp
  local init = get_cursor()
  -- TODO: compare actual bounds
  local count = vim.v.count1
  s, e = self:_search_upward_pp(domain, init, 1)
  p = start and s or e
  if qualifier == 'next' then
    if p and cmp(p, init) > 0 then
      count = count - 1
    end
    if count > 0 then
      s, e = self:_search_forward_pp(domain, init, count)
      p = start and s or e
    end
  elseif qualifier == 'previous' then
    if p and cmp(p, init) < 0 then
      count = count - 1
    end
    if count > 0 then
      s, e = self:_search_backward_pp(domain, init, count)
      p = start and s or e
    end
  else
    assert(false, string.format('unknown qualiier %q', qualifier))
    return
  end
  if not p then
    return
  end
  move_cursor(p)
end

function M:textobject_outer_plain()
  local init = get_cursor()
  local s, e = self:_search_upward_pp('outer', init, vim.v.count1)
  -- if no explicit count was added, look forward if upward failed
  if not s and vim.v.count1 == 1 and vim.v.count == 1 then
    s, e = self:_search_forward_pp('outer', init, vim.v.count1)
  end
  if not s then
    return
  end
  require('flies.objects.utils').update_selection(s, e)
end

function M:textobject_inner_plain()
  local init = get_cursor()
  local s, e = self:_search_upward_pp('inner', init, vim.v.count1)
  -- if no explicit count was added, look forward if upward failed
  if not e and vim.v.count1 == 1 and vim.v.count == 1 then
    -- s, e = self:_search_forward_pp('inner', init, vim.v.count1)
  end
  if not s then
    return
  end
  require('flies.objects.utils').update_selection(s, e)
end

function M:textobject_outer_next()
  local init = get_cursor()
  local s, e = self:_search_forward_pp('outer', init, vim.v.count1)
  if not s then
    return
  end
  require('flies.objects.utils').update_selection(s, e)
end

function M:textobject_inner_next()
  local init = get_cursor()
  local s, e = self:_search_forward_pp('inner', init, vim.v.count1)
  if not s then
    return
  end
  require('flies.objects.utils').update_selection(s, e)
end

function M:textobject_outer_previous()
  local init = get_cursor()
  local s, e = self:_search_backward_pp('outer', init, vim.v.count1)
  if not s then
    return
  end
  require('flies.objects.utils').update_selection(s, e)
end

function M:textobject_inner_previous()
  local init = get_cursor()
  local s, e = self:_search_backward_pp('inner', init, vim.v.count1)
  if not s then
    return
  end
  require('flies.objects.utils').update_selection(s, e)
end

-- this is here to override when needed
function M:post_proc(_, s, e)
  return s, e
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
  local index = 1
  for _, r in ipairs(self:search_all(domain, start, end_)) do
    local s, e = unpack(r)
    s, e = self:post_proc(domain, s, e)
    -- for s, e in self:_search_range_pp_iter(domain, start, end_) do
    local line = s[1] - 1
    local column = s[2]
    table.insert(jump_targets, {
      line = line,
      column = column,
      window = 0,
      object = { s, e },
    })
    table.insert(indirect_jump_targets, {
      index = index,
      score = -manh_dist({ line, column }, cursor_pos),
    })
    index = index + 1
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

function M:textobject_outer_hint()
  self:hint('outer', function(s, e)
    require('flies.objects.utils').update_selection(s, e)
  end)
end

function M:textobject_inner_hint()
  self:hint('inner', function(s, e)
    require('flies.objects.utils').update_selection(s, e)
  end)
end

return M

local M = {}

-- local function search_forward(init, count) end
-- local function search_backward(init, count) end
-- selection_mode, os, is, ie, oe

function M.new()
  return setmetatable({}, { __index = M })
end

function M:move(domain, qualifier, start, _)
  local function m(os, is, ie, oe)
    if not (ie or oe) then
      return
    end
    os, is, ie, oe = M:post_proc(os, is, ie, oe)
    local s, e
    if domain == 'inner' then
      s, e = is, ie
    else
      s, e = os, oe
    end
    local p = start and s or e
    if not p then
      return
    end
    p[2] = p[2] - 1
    vim.api.nvim_win_set_cursor(0, p)
  end
  local init = vim.api.nvim_win_get_cursor(0)
  init[2] = init[2] + 1
  if qualifier == 'next' then
    m(self:search_forward(init, vim.v.count1))
  elseif qualifier == 'previous' then
    m(self:search_backward(init, vim.v.count1))
  elseif qualifier == 'hint' then
    self:hint(domain, m)
  end
end

function M:textobject_outer_plain()
  local init = vim.api.nvim_win_get_cursor(0)
  init[2] = init[2] + 1
  local os, is, ie, oe
  os, is, ie, oe = self:search_upward(init, vim.v.count1)
  -- if no explicit count was added, look forward if upward failed
  if not (ie or oe) and vim.v.count1 == 1 and vim.v.count == 1 then
    os, is, ie, oe = self:search_forward(init, vim.v.count1)
  end
  if not (ie or oe) then
    return
  end
  os, is, ie, oe = self:post_proc(os, is, ie, oe)
  require('flies.objects.utils').update_selection(os, oe)
end

function M:textobject_inner_plain()
  local init = vim.api.nvim_win_get_cursor(0)
  init[2] = init[2] + 1
  local os, is, ie, oe
  os, is, ie, oe = self:search_upward(init, vim.v.count1)
  if not (ie or oe) and vim.v.count1 == 1 then
    os, is, ie, oe = self:search_forward(init, vim.v.count1)
  end
  if not ie and not oe then
    return
  end
  os, is, ie, oe = self:post_proc(os, is, ie, oe)
  require('flies.objects.utils').update_selection(is, ie)
end

function M:textobject_outer_next()
  local init = vim.api.nvim_win_get_cursor(0)
  init[2] = init[2] + 1
  local os, is, ie, oe
  os, is, ie, oe = self:search_forward(init, vim.v.count1)
  if not (ie or oe) then
    return
  end
  os, is, ie, oe = self:post_proc(os, is, ie, oe)
  require('flies.objects.utils').update_selection(os, oe)
end

function M:textobject_inner_next()
  local init = vim.api.nvim_win_get_cursor(0)
  init[2] = init[2] + 1
  local os, is, ie, oe
  os, is, ie, oe = self:search_forward(init, vim.v.count1)
  if not (ie or oe) then
    return
  end
  os, is, ie, oe = self:post_proc(os, is, ie, oe)
  require('flies.objects.utils').update_selection(is, ie)
end

function M:textobject_outer_previous()
  local init = vim.api.nvim_win_get_cursor(0)
  init[2] = init[2] + 1
  local os, is, ie, oe
  os, is, ie, oe = self:search_backward(init, vim.v.count1)
  if not (ie or oe) then
    return
  end
  os, is, ie, oe = self:post_proc(os, is, ie, oe)
  require('flies.objects.utils').update_selection(os, oe)
end

function M:textobject_inner_previous()
  local init = vim.api.nvim_win_get_cursor(0)
  init[2] = init[2] + 1
  local os, is, ie, oe
  os, is, ie, oe = self:search_backward(init, vim.v.count1)
  if not (ie or oe) then
    return
  end
  os, is, ie, oe = self:post_proc(os, is, ie, oe)
  require('flies.objects.utils').update_selection(is, ie)
end

-- this is here to override when needed
function M:post_proc(os, is, ie, oe)
  return os, is, ie, oe
end

function M:hint(domain, cb)
  require('hop').hint_with_callback(
    self:get_jump_target_gtr(domain),
    require('hop').opts,
    function(res)
      cb(unpack(res.object))
    end
  )
end

function M:textobject_outer_hint()
  self:hint('outer', function(os, _, _, oe)
    require('flies.objects.utils').update_selection(os, oe)
  end)
end

function M:textobject_inner_hint()
  self:hint('inner', function(_, is, ie, _)
    require('flies.objects.utils').update_selection(is, ie)
  end)
end

function M:get_jump_target_gtr(domain)
  local manh_dist = require('hop.jump_target').manh_dist
  return function(_)
    -- 0,0 based
    local context = require('hop.window').get_window_context()
    context = context[1].contexts[1]
    local line = context.top_line + 1
    local max = context.bot_line + 1
    local cursor_pos = context.cursor_pos
    local col = 1
    local jump_targets = {}
    local indirect_jump_targets = {}
    local index = 1
    local old = {}
    while true do
      local os, is, ie, oe = self:search_forward({ line, col }, 1)
      if not (oe or ie) then
        break
      end
      os, is, ie, oe = self:post_proc(os, is, ie, oe)
      local res
      if domain == 'inner' then
        res = is
      elseif domain == 'outer' then
        res = os
      end
      if res then
        line, col = unpack(res)
        if old[1] == line and old[2] == col then
          print 'Error, search_forward is not forwarding!'
          return
        end
        old = { line, col }
        -- TODO: does it matter if res is of screen?
        table.insert(jump_targets, {
          line = line - 1,
          column = col,
          window = 0,
          object = { os, is, ie, oe },
        })
        table.insert(indirect_jump_targets, {
          index = index,
          score = -manh_dist({ line, col }, cursor_pos),
        })
        index = index + 1
      end
      if M.no_nest then
        line, col = unpack(os or is)
      else
        line, col = unpack(oe or ie)
      end
      if line > max then
        break
      end
      col = col + 1
    end
    return {
      jump_targets = jump_targets,
      indirect_jump_targets = indirect_jump_targets,
    }
  end
end

return M

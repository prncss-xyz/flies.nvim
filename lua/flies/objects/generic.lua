local M = {}

-- local function search_forward(init, count) end
-- local function search_backward(init, count) end
-- selection_mode, os, is, ie, oe

function M.new()
  return setmetatable({}, { __index = M })
end

-- query[name('textobject', domain, qualifier)](query, mode)

function M:search(domain, qualifier, init, count)
  dump(1)
  if qualifier == 'up' then
    return self:search_upward(domain, init, count)
  end
  if qualifier == 'smart' then
    local a, b, c, d = self:search_upward(domain, init, 1)
    if a then
      return a, b, c, d
    end
    return self:search_forward(domain, init, 1)
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

function M:textobject(domain, qualifier)
  if qualifier == 'plain' then
    if vim.v.count == vim.v.count1 then
      qualifier = 'up'
    else
      qualifier = 'smart'
    end
  end
  local pos = require('flies.utils').get_cursor()
  self:search_cb(domain, qualifier, pos, vim.v.count1, function(a, b, c, d)
    if not a then
      return
    end
    local s, e
    if c then
      s, e = a, d
      require('flies').cache = {
        pos = pos,
        s = s,
        e = e,
      }
    else
      s, e = a, b
      require('flies').cache = { pos = pos }
    end
    require('flies.objects.utils').update_selection(s, e)
  end)
end

function M:motion(domain, qualifier, start)
  if qualifier == 'hint' then
    self:hint(domain, require('flies.utils').set_cursor)
    return
  end
  local s, e, p
  local cmp = require('flies.objects.utils').cmp
  local init = require('flies.utils').get_cursor()
  -- TODO: compare actual bounds
  local count = vim.v.count1
  s, e = self:search_upward(domain, init, 1)
  p = start and s or e
  if qualifier == 'next' then
    if p and cmp(p, init) > 0 then
      count = count - 1
    end
    if count > 0 then
      s, e = self:search_forward(domain, init, count)
      p = start and s or e
    end
  elseif qualifier == 'previous' then
    if p and cmp(p, init) < 0 then
      count = count - 1
    end
    if count > 0 then
      s, e = self:search_backward(domain, init, count)
      p = start and s or e
    end
  else
    assert(false, string.format('unknown qualiier %q', qualifier))
    return
  end
  if not p then
    return
  end
  require('flies.utils').set_cursor(p)
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
    -- for s, e in self:_search_range_iter(domain, start, end_) do
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

return M

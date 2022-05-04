local M = {}

local G = _G.Flies or {}
_G.Flies = G

local t = require('flies.utils').t

local state
local will_repeat
local index
local saved_state

function M.querier(cb)
  local res = M.querier_step(cb)
  M.querier_save()
  return res
end

function M.querier_step(cb)
  index = index + 1
  if will_repeat then
    return saved_state[index]
  end
  state[index] = cb()
  return state[index]
end

function M.querier_save()
  if not will_repeat then
    saved_state = state
    state = {}
  end
  index = 0
end

function M.pre_dot()
  will_repeat = true
  return '.' .. t ":lua require'flies.repeater'.post_dot()<cr>"
end

function M.post_dot()
  will_repeat = false
end

function M.setup()
  M.querier_save()
  vim.api.nvim_set_keymap(
    'n',
    '.',
    -- don't know how to escape dots (loaded["flies.repeater"]) here
    'v:lua.package.loaded.flies.repeater.pre_dot()',
    { expr = true, noremap = true }
  )
end

return M

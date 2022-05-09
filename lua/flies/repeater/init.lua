local M = {}

-- move
-- move - moity
-- add obj - add char
-- add obj - moity - add char
-- op - moity
-- moity (xmode)

local G = _G.Flies or {}
_G.Flies = G

local t = require('flies.utils').t

local state
local will_repeat
local index
local saved_state

function M.init()
  if not will_repeat then
    saved_state = state
    state = {}
  end
  index = 0
end

function M.cancel()
  state = saved_state
end

function M.querier(cb)
  index = index + 1
  if will_repeat then
    return saved_state[index]
  end
  state[index] = cb()
  if state[index] == nil then
    M.cancel()
  else
    return state[index]
  end
end

function M.pre_dot()
  will_repeat = true
  return '.' .. t ":lua require'flies.repeater'.post_dot()<cr>"
end

function M.post_dot()
  will_repeat = false
end

function M.setup()
  vim.api.nvim_set_keymap(
    'n',
    '.',
    -- don't know how to escape dots (loaded["flies.repeater"]) here
    'v:lua.package.loaded.flies.repeater.pre_dot()',
    { expr = true, noremap = true }
  )
end

return M

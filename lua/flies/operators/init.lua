local M = {}

function M.setup()
  require('flies.operators.explode'):register()
  require('flies.operators.substitute'):register()
  require('flies.operators.swap'):register()
  require('flies.operators.wrap'):register()
end

return M

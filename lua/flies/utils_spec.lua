local M = require 'flies.utils'

describe('get_path', function()
  it('should return nil when path does not exist', function()
    assert.is.falsy(nil, M.get_path({ toto = {} }, 'toto', 'titi'))
  end)
  it('should return value when path exists', function()
    assert.are.same(3, M.get_path({ toto = { titi = 3 } }, 'toto', 'titi'))
  end)
end)

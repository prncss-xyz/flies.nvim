local M = require 'flies.objects.subline'
local with_fake_buf = require('flies.objects.test_util').with_fake_buf

describe('bigword', function()
  it('should respect basic pattern', function()
    local t = M.bigword()
    assert.is.falsy(t:search_upward('both', { 1, 2 }, 1))
    with_fake_buf({ ' aaa.bbb cc ' }, function()
      assert.are.same(
        { { 1, 2 }, { 1, 2 }, { 1, 8 }, { 1, 9 } },
        { t:search_upward('both', { 1, 2 }, 1) }
      )
    end)
  end)
  it('should respect count', function()
    local t = M.bigword()
    with_fake_buf({ '  aa  cc ' }, function()
      assert.are.same(
        { { 1, 7 }, { 1, 7 }, { 1, 8 }, { 1, 9 } },
        { t:search_forward('both', { 1, 1 }, 2) }
      )
    end)
  end)
  it('should search backward', function()
    local t = M.bigword()
    with_fake_buf({ '  aa  cc ' }, function()
      assert.are.same(
        { { 1, 3 }, { 1, 3 }, { 1, 4 }, { 1, 6 } },
        { t:search_backward('both', { 1, 9 }, 2) }
      )
    end)
  end)
end)
-- TODO: exact vimword spec
describe('vimword', function()
  it('search vimword', function()
    local t = M.vimword()
    with_fake_buf({ ' bbb.cc   !!' }, function()
      assert.are.same(
        { { 1, 2 }, { 1, 2 }, { 1, 4 }, { 1, 4 } },
        { t:search_upward('both', { 1, 2 }, 1) }
      )
    end)
  end)
end)
describe('variable segment', function()
  it('description', function()
    local t = M.variable_segment()
    with_fake_buf({ ' bb_cc ' }, function()
      assert.are.same(
        { { 1, 2 }, { 1, 2 }, { 1, 3 }, { 1, 4 } },
        { t:search_upward('both', { 1, 2 }, 1) }
      )
      assert.are.same(
        { { 1, 4 }, { 1, 5 }, { 1, 6 }, { 1, 6 } },
        { t:search_upward('both', { 1, 5 }, 1) }
      )
    end)
  end)
end)
describe('string ', function()
  it('should respect basic string', function()
    local t = M.string('"', "'")
    with_fake_buf({ ' "as" ' }, function()
      assert.are.same(
        { { 1, 2 }, { 1, 3 }, { 1, 4 }, { 1, 5 } },
        { t:search_upward('both', { 1, 2 }, 1) }
      )
    end)
  end)
  it('should respect escaped characters', function()
    local t = M.string('"', "'")
    with_fake_buf({ ' "\\"a" ' }, function()
      assert.are.same(
        { { 1, 2 }, { 1, 3 }, { 1, 5 }, { 1, 6 } },
        { t:search_upward('both', { 1, 2 }, 1) }
      )
    end)
  end)
  it('should stop only with matching quote', function()
    local t = M.string('"', "'")
    with_fake_buf({ ' "\'a" ' }, function()
      assert.are.same(
        { { 1, 2 }, { 1, 3 }, { 1, 4 }, { 1, 5 } },
        { t:search_upward('both', { 1, 2 }, 1) }
      )
    end)
  end)
  it('should respect empty strings', function()
    local t = M.string('"', "'")
    with_fake_buf({ ' "" ' }, function()
      assert.are.same(
        { { 1, 2 }, { 1, 3 }, nil, { 1, 3 } },
        { t:search_upward('both', { 1, 2 }, 1) }
      )
    end)
  end)
end)

local M = require 'flies.objects.pair'
local with_fake_buf = require('flies.objects.test_util').with_fake_buf

local b = M.new { { '(', ')' }, { '{', '}' } }

describe('should match paren around cursor', function()
  it('should match inside', function()
    with_fake_buf({ ' ( ) ' }, function()
      assert.are.same(
        { { 1, 2 }, { 1, 3 }, { 1, 3 }, { 1, 4 } },
        { b:search_upward('both', { 1, 3 }, 1) }
      )
    end)
  end)
  it('should match on left border', function()
    with_fake_buf({ ' ( ) ' }, function()
      assert.are.same(
        { { 1, 2 }, { 1, 3 }, { 1, 3 }, { 1, 4 } },
        { b:search_upward('both', { 1, 2 }, 1) }
      )
    end)
  end)
  it('should match on right border', function()
    with_fake_buf({ ' ( ) ' }, function()
      assert.are.same(
        { { 1, 2 }, { 1, 3 }, { 1, 3 }, { 1, 4 } },
        { b:search_upward('both', { 1, 4 }, 1) }
      )
    end)
  end)
  it('should not match outside', function()
    with_fake_buf({ ' ( ) ' }, function()
      assert.are.same({}, { b:search_upward('both', { 1, 1 }, 1) })
      assert.are.same({}, { b:search_upward('both', { 1, 5 }, 1) })
    end)
  end)
  it('should express void inside with a nil, {coords} pair', function()
    with_fake_buf({ ' () ' }, function()
      assert.are.same(
        { { 1, 2 }, nil, { 1, 3 }, { 1, 3 } },
        { b:search_upward('both', { 1, 2 }, 1) }
      )
    end)
  end)
  it('should match across lines (linebreaks inside)', function()
    with_fake_buf({ '(   ', 'aaa', '   )' }, function()
      assert.are.same(
        { { 1, 1 }, { 1, 2 }, { 3, 3 }, { 3, 4 } },
        { b:search_upward('both', { 1, 1 }, 1) }
      )
    end)
  end)
  it('should match across lines (linebreaks at inside border)', function()
    with_fake_buf({ ' (', 'aaa', ') ' }, function()
      assert.are.same(
        { { 1, 2 }, { 2, 1 }, { 2, 3 }, { 3, 1 } },
        { b:search_upward('both', { 1, 2 }, 1) }
      )
    end)
  end)
  it('should respect count', function()
    with_fake_buf({ ' ( { } ) ' }, function()
      assert.are.same(
        { { 1, 2 }, { 1, 3 }, { 1, 7 }, { 1, 8 } },
        { b:search_upward('both', { 1, 5 }, 2) }
      )
    end)
  end)
  it('should not match with excessive count', function()
    with_fake_buf({ ' ( { } ) ' }, function()
      assert.are.same({}, { b:search_upward('both', { 1, 5 }, 3) })
    end)
  end)
  it('should respect balance', function()
    with_fake_buf({ ' ( { ) ' }, function()
      assert.are.same(
        { { 1, 2 }, { 1, 3 }, { 1, 5 }, { 1, 6 } },
        { b:search_upward('both', { 1, 2 }, 1) }
      )
      -- FIXME: is it what we really really want
      assert.are.same(
        { { 1, 2 }, { 1, 3 }, { 1, 5 }, { 1, 6 } },
        { b:search_upward('both', { 1, 3 }, 1) }
      )
      assert.are.same(
        { { 1, 2 }, { 1, 3 }, { 1, 5 }, { 1, 6 } },
        { b:search_upward('both', { 1, 4 }, 1) }
      )
    end)
  end)
  it('sould respect empty paren', function()
    with_fake_buf({ '{}' }, function()
      assert.are.same(
        { { 1, 1 }, { 1, 2 }, nil, { 1, 2 } },
        { b:search_upward('both', { 1, 1 }, 1) }
      )
    end)
  end)
end)

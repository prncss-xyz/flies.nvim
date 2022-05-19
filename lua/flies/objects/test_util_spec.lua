local M = require 'flies.objects.test_util'
local with_fake_buf = M.with_fake_buf

describe('row_forward_iterator', function()
  it('iterates forward from begening', function()
    with_fake_buf({ 'aaa', 'bbb', 'ccc' }, function()
      local t = {}
      for row, line in require('flies.objects.utils').row_forward_iterator() do
        table.insert(t, { row, line })
      end
      assert.are.same({ { 1, 'aaa' }, { 2, 'bbb' }, { 3, 'ccc' } }, t)
    end)
  end)
  it('iterates forward from arbitrary start', function()
    with_fake_buf({ 'aaa', 'bbb', 'ccc' }, function()
      local t = {}
      for row, line in require('flies.objects.utils').row_forward_iterator(2) do
        table.insert(t, { row, line })
      end
      assert.are.same({ { 2, 'bbb' }, { 3, 'ccc' } }, t)
    end)
  end)
end)

describe('row_backward_iterator', function()
  it('iterates backward from begening', function()
    with_fake_buf({ 'aaa', 'bbb', 'ccc' }, function()
      local t = {}
      for row, line in require('flies.objects.utils').row_backward_iterator() do
        table.insert(t, { row, line })
      end
      assert.are.same({ { 3, 'ccc' }, { 2, 'bbb' }, { 1, 'aaa' } }, t)
    end)
  end)
  it('iterates backward from arbitrary start', function()
    with_fake_buf({ 'aaa', 'bbb', 'ccc' }, function()
      local t = {}
      for row, line in require('flies.objects.utils').row_backward_iterator(2) do
        table.insert(t, { row, line })
      end
      assert.are.same({ { 2, 'bbb' }, { 1, 'aaa' } }, t)
    end)
  end)
end)

describe('get_row', function()
  it('git give nth row content', function()
    with_fake_buf({ 'aaa', 'bbb', 'ccc' }, function()
      assert.are.same('bbb', require('flies.objects.utils').get_row(2))
    end)
  end)
end)

describe('__index', function()
  it('should return unmocked functions', function()
    with_fake_buf({}, function()
      assert.is.truthy(require('flies.objects.utils').cmp)
    end)
  end)
end)

describe('iter_to_list', function()
  it('should build a {start, end} list from iterator', function()
    local function iter(_, i)
      i = i + 1
      if i <= 3 then
        return i, { i, i }, { i, i }
      end
    end
    assert.are.same(
      { { 1, 1 }, { 1, 1 } },
      { { 2, 2 }, { 2, 2 } },
      { { 3, 3 }, { 3, 3 } },
      M.iter_to_list(iter, nil, 0)
    )
  end)
end)

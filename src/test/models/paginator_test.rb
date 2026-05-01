require 'test_helper'

class PaginatorTest < ActiveSupport::TestCase
  test "single page yields just that page" do
    assert_equal [1], Paginator.new(1, 1).entries
  end

  test "three pages, all consecutive, no gap" do
    assert_equal [1, 2, 3], Paginator.new(1, 3).entries
  end

  test "page 1 of 10 shows window then gap then last" do
    assert_equal [1, 2, 3, :gap, 10], Paginator.new(1, 10).entries
  end

  test "page 5 of 10 shows first, gap, window, gap, last" do
    assert_equal [1, :gap, 3, 4, 5, 6, 7, :gap, 10], Paginator.new(5, 10).entries
  end

  test "page 10 of 10 shows first then gap then window" do
    assert_equal [1, :gap, 8, 9, 10], Paginator.new(10, 10).entries
  end

  test "no gap when first and window are adjacent" do
    assert_equal [1, 2, 3, 4, 5, 6, :gap, 10], Paginator.new(4, 10).entries
  end

  test "no gap when window and last are adjacent" do
    assert_equal [1, :gap, 5, 6, 7, 8, 9, 10], Paginator.new(7, 10).entries
  end

  test "small total fits without gaps" do
    assert_equal [1, 2, 3, 4, 5], Paginator.new(3, 5).entries
  end

  test "first_page? and last_page?" do
    assert Paginator.new(1, 5).first_page?
    refute Paginator.new(2, 5).first_page?
    assert Paginator.new(5, 5).last_page?
    refute Paginator.new(4, 5).last_page?
  end

  test "prev_page and next_page" do
    paginator = Paginator.new(3, 5)
    assert_equal 2, paginator.prev_page
    assert_equal 4, paginator.next_page
  end
end

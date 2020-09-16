defmodule CrawlyUIWeb.PaginationHelpersTest do
  use ExUnit.Case, async: true

  alias CrawlyUIWeb.PaginationHelpers

  setup do
    Application.put_env(:crawly_ui, :page_size, 1)
    on_exit(fn -> Application.put_env(:crawly_ui, :page_size, 10) end)
  end

  describe "render_pages/2" do
    test "styled html for the view's page number" do
      assert PaginationHelpers.render_pages(1, 1) == "<strong> 1 </strong>"
    end

    test "link to other pages" do
      assert PaginationHelpers.render_pages(1, 2) ==
               "<a phx-click=\"goto_page\" phx-value-page=2> 2 </a>"
    end

    test "for .. string" do
      assert PaginationHelpers.render_pages(1, "..") == ".."
    end
  end

  describe "render_goto_next/2" do
    test "link to next page" do
      assert PaginationHelpers.render_goto_next(2, [1, 2, 3]) ==
               "<a phx-click=\"goto_page\" phx-value-page=3> >> </a>"
    end

    test "do nothing for last page" do
      assert PaginationHelpers.render_goto_next(3, [1, 2, 3]) == nil
    end

    test "when there is less or equal to 1 page" do
      assert PaginationHelpers.render_goto_next(1, [1]) == nil
    end
  end

  describe "render_goto_prev/1" do
    test "link to previous page" do
      assert PaginationHelpers.render_goto_prev(2, [1, 2, 3]) ==
               "<a phx-click=\"goto_page\" phx-value-page=1> << </a>"
    end

    test "do nothing for last page" do
      assert PaginationHelpers.render_goto_prev(1, [1, 2, 3]) == nil
    end

    test "when there is less or equal to 1 page" do
      assert PaginationHelpers.render_goto_prev(1, [1]) == nil
    end
  end

  describe "paginate/2" do
    test "get the rows belonging to a page" do
      assert PaginationHelpers.paginate([1, 2, 3], 2) == [2]
    end

    test "for empty list" do
      assert PaginationHelpers.paginate([], 2) == []
    end
  end

  describe "list_pages/2" do
    test "when there is no data" do
      assert PaginationHelpers.list_pages(1, []) == []
    end

    test "when number for pages is below 11" do
      list = Enum.to_list(1..10)
      data = Enum.map(list, fn x -> "data_#{x}" end)

      assert PaginationHelpers.list_pages(1, data) == list
    end

    test "when current page is less than 6" do
      list = Enum.to_list(1..11)
      data = Enum.map(list, fn x -> "data_#{x}" end)

      assert PaginationHelpers.list_pages(3, data) == [1, 2, 3, 4, 5, 6, "..", 11]
    end

    test "when current page is less than the total number of pages - 5" do
      list = Enum.to_list(1..20)
      data = Enum.map(list, fn x -> "data_#{x}" end)

      assert PaginationHelpers.list_pages(17, data) == [1, "..", 15, 16, 17, 18, 19, 20]
    end

    test "current page is not close to first or last page" do
      list = Enum.to_list(1..30)
      data = Enum.map(list, fn x -> "data_#{x}" end)

      assert PaginationHelpers.list_pages(15, data) ==
               [1, "..", 11, 12, 13, 14, 15, 16, 17, 18, 19, "..", 30]
    end
  end
end

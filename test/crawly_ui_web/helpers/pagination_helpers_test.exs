defmodule CrawlyUIWeb.PaginationHelpersTest do
  use ExUnit.Case, async: true

  alias CrawlyUIWeb.PaginationHelpers

  test "render pagination links when there is 1 page" do
    assert PaginationHelpers.pagination_links(1, 0) =~
             "<nav>\n<ul class=\"pagination\">\n\n\n\n</ul>\n</nav>\n"
  end

  test "render pagination links when there are less than 11 pages" do
    pagination = PaginationHelpers.pagination_links(5, 10)

    assert pagination =~
             "<a href=\"#\" phx-click=\"goto_page\" phx-value-page=4> << </a>"

    assert pagination =~
             "<a href=\"#\" phx-click=\"goto_page\" phx-value-page=6> >> </a>"

    Enum.each(1..10, fn page -> match_page(pagination, page) end)
  end

  test "render when current page is less than 6" do
    pagination = PaginationHelpers.pagination_links(1, 11)

    refute pagination =~ "<<"

    Enum.each([1, 2, 3, 4, 5, 6, 11], fn page -> match_page(pagination, page) end)

    refute String.contains?(pagination, ">7<")
  end

  test "render when current page is less than the total number of pages - 5" do
    pagination = PaginationHelpers.pagination_links(11, 11)

    refute pagination =~ ">>"

    Enum.each([1, 6, 7, 8, 9, 10, 11], fn page -> match_page(pagination, page) end)

    refute String.contains?(pagination, ">2<")
  end

  test "render when current page is not close to first or last page" do
    pagination = PaginationHelpers.pagination_links(15, 30)

    Enum.each([1, 11, 12, 13, 14, 15, 16, 17, 18, 19, 30], fn page ->
      match_page(pagination, page)
    end)

    refute String.contains?(pagination, ">2<")
    refute String.contains?(pagination, ">29<")
  end

  defp match_page(pagination, page) do
    assert String.contains?(pagination, Integer.to_string(page))
  end

  test "id_based pagination" do
    pagination = PaginationHelpers.id_based(last_id: 1, first_id: 50, previous_page: false, next_page: true)

    assert String.contains?(pagination, "?last_id=50")
    assert String.contains?(pagination, "?first_id=1")
    assert String.contains?(pagination, "?first_id=1")
  end
end

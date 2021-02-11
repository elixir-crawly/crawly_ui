defmodule CrawlyUIWeb.AvailableSpidersLiveTest do
  import CrawlyUI.DataCase

  use CrawlyUIWeb.ConnCase
  import Phoenix.LiveViewTest

  alias CrawlyUI.SpiderManager
  import Mock

  test "mount spider view to show all available spider", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/available_spiders")

    assert html =~ "Available for schedule"
  end

  test "redirect to index when a spider job starts successfully", %{conn: conn} do
    with_mock CrawlyUI.SpiderManager, [],
      start_spider: fn
        _, _ -> {:ok, :started}
      end do
      {:ok, view, _html} = live(conn, "/available_spiders")

      render_click(view, :schedule_spider, %{
        "spider" => "Crawly.TestSpider",
        "node" => "test@node"
      })

      flash = assert_redirect(view, "/")

      assert flash["info"] ==
               "Spider scheduled successfully. It might take a bit of time before items will appear here..."
    end
  end

  test "refresh page when a spider job failed at starting", %{conn: conn} do
    with_mock CrawlyUI.SpiderManager, [],
      start_spider: fn
        _, _ -> {:error, "Failed"}
      end do
      {:ok, view, _html} = live(conn, "/available_spiders")

      render_click(view, :schedule_spider, %{
        "spider" => "Crawly.TestSpider",
        "node" => "test@node"
      })

      flash = assert_redirect(view, "/available_spiders")

      assert flash["error"] ==
               "{:error, \"Failed\"}"
    end
  end

  # test "pick node from list and render it's spiders", %{conn: conn} do
  #   with_mocks([
  #     {Node, [], list: fn -> ["example1@node", "example2@node"] end},
  #     {SpiderManager, [], list_spiders: fn node -> conditionally_mocked(node) end}
  #   ]) do
  #     {:ok, view, _html} = live(conn, "/available_spiders")

  #     render_click(view, :pick_node, %{
  #       "node" => "example2@node"
  #     })

  #     assert render(view) =~
  #       "Test.Spider3"
  #     assert render(view) =~
  #       "Test.Spider4"
  #   end
  # end

  # defp conditionally_mocked(node) do
  #   case node do
  #     "example1@node" -> ["Test.Spider1", "Test.Spider2"]
  #     "example2@node" -> ["Test.Spider3", "Test.Spider4"]
  #   end
  # end
end

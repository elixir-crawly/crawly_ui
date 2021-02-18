defmodule CrawlyUIWeb.AvailableSpidersLiveTest do
  use CrawlyUIWeb.ConnCase
  import Phoenix.LiveViewTest
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

  test "pick node from list and render it's spiders", %{conn: conn} do
    with_mock CrawlyUI.SpiderManager, [],
      list_spiders: fn _ ->
        ["Test.Spider3", "Test.Spider4"]
      end do
      {:ok, view, _html} = live(conn, "/available_spiders")

      refute render(view) =~
               "Test.Spider3"

      refute render(view) =~
               "Test.Spider4"

      render_click(view, :pick_node, %{
        "node" => "example2@node"
      })

      assert render(view) =~
               "Test.Spider3"

      assert render(view) =~
               "Test.Spider4"
    end
  end
end

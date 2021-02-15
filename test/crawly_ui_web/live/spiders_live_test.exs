defmodule CrawlyUIWeb.SpidersLiveTest do
  import CrawlyUI.DataCase

  use CrawlyUIWeb.ConnCase
  import Phoenix.LiveViewTest
  import CrawlyUI.DataCase

  import Mock

  test "mount spider view to show all available spider", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/spiders")

    assert html =~ "Visual spiders"
  end

  test "display spider names when exists", %{conn: conn} do
    spider = insert_spider()

    {:ok, _view, html} = live(conn, "/spiders")

    assert html =~ spider.name
  end

  test "supports pagination", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/spiders")

    assert view
           |> render_click(:goto_page, %{"page" => "2"})
           |> follow_redirect(conn, "/spiders?page=2")
  end

  test "redirects to spider show page", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/spiders")

    assert view
           |> render_click(:show_spider, %{"spider" => "TestSpider"})
           |> follow_redirect(conn, "/spider?spider=TestSpider")
  end

  test "redirects to edit spider page", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/spiders")

    assert view
           |> render_click(:edit_spider, %{"spider" => "TestSpider"})
           |> follow_redirect(conn, "/spider/new?spider=TestSpider")
  end

  test "redirect to / when a spider job starts successfully", %{conn: conn} do
    with_mocks([
      {CrawlyUI, [], create_spider: fn "test@node", "Crawly" -> true end},
      {CrawlyUI.SpiderManager, [], start_spider: fn "test@node", "Crawly" -> {:ok, :started} end}
    ]) do
      insert_spider()
      {:ok, view, _html} = live(conn, "/spiders")

      render_click(view, :schedule_autospider, %{
        "spider" => "Crawly",
        "node" => "test@node"
      })

      flash = assert_redirect(view, "/")

      assert flash["info"] ==
               "Spider was scheduled"
    end
  end
end

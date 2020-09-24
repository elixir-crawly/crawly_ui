defmodule CrawlyUIWeb.ScheduleLiveTest do
  use CrawlyUIWeb.ConnCase, async: false
  import Phoenix.LiveViewTest

  import Mock

  setup_with_mocks([
    {CrawlyUI.SpiderManager, [],
     [
       list_spiders: fn _ -> ["Crawly.TestSpider"] end,
       start_spider: fn
         "test", _ -> {:ok, :started}
         "other_node", _ -> {:error, "Failed"}
       end
     ]}
  ]) do
    :ok
  end

  test "mount view for pick node", %{conn: conn} do
    {:ok, view, html} = live(conn, "/schedule")
    assert CrawlyUIWeb.ScheduleLive = view.module
    assert html =~ "Node"

    Process.sleep(1000)

    assert render(view) =~ "Node"
  end

  test "mount view for pick spider", %{conn: conn} do
    {:ok, view, html} = live(conn, "/schedule/spider?node=test")
    assert CrawlyUIWeb.ScheduleLive = view.module
    assert html =~ "Spider"
    assert render(view) =~ "Crawly.TestSpider"

    Process.sleep(1000)

    assert render(view) =~ "Crawly.TestSpider"
  end

  test "redirect to pick spider", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/schedule")

    render_click(view, :spider_picked, %{node: "worker@test"})
    assert_redirect(view, "/schedule/spider?node=worker%40test")
  end

  test "redirect to index when a spider job starts successfully", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/schedule/spider?node=test")
    render_click(view, :schedule_spider, %{spider: "Crawly.TestSpider"})
    flash = assert_redirect(view, "/")

    assert flash["info"] ==
             "Spider scheduled successfully. It might take a bit of time before items will appear here..."
  end

  test "redirect to schedule page when a spider job failed at starting", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/schedule/spider?node=other_node")
    render_click(view, :schedule_spider, %{spider: "Crawly.TestSpider"})
    flash = assert_redirect(view, "/schedule")

    assert flash["error"] ==
             "{:error, \"Failed\"}"
  end
end

defmodule CrawlyUIWeb.CreateSpiderLiveTest do
  use CrawlyUIWeb.ConnCase
  import Phoenix.LiveViewTest

  test "mount new spider", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/spider/new")
    assert CrawlyUIWeb.NewSpiderLive = view.module
  end

  test "Possible to move to step1 with data", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/spider/new")
    data = %{"name" => "Spider1", "fields" => "url,title"}
    assert render_submit(view, "step1", data) =~ "Define crawling rules"
  end

  test "Possible to move to step2 with data", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/spider/new")
    data = %{"start_urls" => "http://example.com", "follow_urls" => "blog"}
    assert render_submit(view, "step2", data) =~ "Item extractors list"
  end

  test "It's possible to open add rule page", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/spider/new")
    data = %{"pageUrl" => "http://example.com/page/1"}
    assert render_submit(view, "step3", data) =~ "Define extractors"
  end

  test "It's possible to add rules", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/spider/new")

    data = %{"pageUrl" => "http://example.com/page/1"}
    render_submit(view, "step3", data)

    data = %{"url" => "response_url", "title" => "article h1"}
    assert render_submit(view, "rule_added", data) =~ "<td>http://example.com/page/1</td>"
  end

  test "It's possible to delete rule", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/spider/new")

    data = %{"pageUrl" => "http://example.com/page/1"}
    render_submit(view, "step3", data)

    data = %{"url" => "response_url", "title" => "article h1"}
    assert render_submit(view, "rule_added", data) =~ "<td>http://example.com/page/1</td>"

    assert render_click(view, "rule_delete", %{"url" => "http://example.com/page/1"})
           =~ "<table><thead><tr><th>Page</th><th>Actions</th></tr></thead><tbody></tbody></table>"
  end
end
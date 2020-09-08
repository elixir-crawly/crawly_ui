defmodule CrawlyUIWeb.PageViewTest do
  use CrawlyUIWeb.ConnCase, async: true

  import Phoenix.View

  test "show index.html" do
    assert render_to_string(CrawlyUIWeb.PageView, "index.html", []) =~ "Web Crawling Dashboard."
  end
end

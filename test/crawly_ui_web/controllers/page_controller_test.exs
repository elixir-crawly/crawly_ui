defmodule CrawlyUIWeb.PageControllerTest do
  use CrawlyUIWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Schedule"
  end
end

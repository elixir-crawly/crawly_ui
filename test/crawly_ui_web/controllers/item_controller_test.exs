defmodule CrawlyUIWeb.ItemControllerTest do
  use CrawlyUIWeb.ConnCase

  import CrawlyUI.DataCase

  test "index shows all items from a job", %{conn: conn} do
    job = insert_job()
    conn = get(conn, Routes.item_path(conn, :index, job.id))
    assert html_response(conn, 200) =~ "Items"
  end

  test "index with search string", %{conn: conn} do
    job = insert_job()
    conn = get(conn, Routes.item_path(conn, :index, job.id), search: "search string")
    assert html_response(conn, 200) =~ "Items"
    assert html_response(conn, 200) =~ "placeholder=\"search string\""
  end

  test "show shows an item's data", %{conn: conn} do
    job = insert_job()
    item = insert_item(job.id)
    conn = get(conn, Routes.item_path(conn, :show, job.id, item.id))
    assert html_response(conn, 200) =~ "Item viewer"
  end
end

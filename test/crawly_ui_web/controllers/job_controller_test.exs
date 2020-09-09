defmodule CrawlyUIWeb.JobControllerTest do
  use CrawlyUIWeb.ConnCase

  import CrawlyUI.DataCase

  import Mock

  test "index when there is no job presents", %{conn: conn} do
    conn = get(conn, Routes.job_path(conn, :index))
    assert html_response(conn, 200) =~ "Welcome to Crawly UI"
  end

  test "index shows a list of jobs", %{conn: conn} do
    insert_job()
    conn = get(conn, Routes.job_path(conn, :index))
    assert html_response(conn, 200) =~ "Jobs"
  end

  test "pick_node shows a list of nodes", %{conn: conn} do
    conn = get(conn, Routes.job_path(conn, :pick_node))
    assert html_response(conn, 200) =~ "Node"
  end

  test "pick_spider shows a list of spiders", %{conn: conn} do
    with_mock :rpc, [:unstick], call: fn _, Crawly, :list_spiders, [] -> [] end do
      conn = get(conn, Routes.job_path(conn, :pick_spider), node: "spider@test")
      assert html_response(conn, 200) =~ "Spider"
    end
  end
end

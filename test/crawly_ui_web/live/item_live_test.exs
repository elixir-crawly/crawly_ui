defmodule CrawlyUIWeb.ItemLiveTest do
  import CrawlyUI.DataCase

  use CrawlyUIWeb.ConnCase
  import Phoenix.LiveViewTest

  setup do
    job = insert_job(%{inserted_at: inserted_at(6 * 60), state: "running"})
    item = insert_item(job.id, inserted_at(50), %{"url" => "http://example.com"})

    [job_id: job.id, item_id: item.id]
  end

  test "mount view for items index", %{conn: conn, job_id: job_id} do
    {:ok, view, html} = live(conn, "/jobs/#{job_id}/items")
    assert CrawlyUIWeb.ItemLive = view.module

    assert html =~ "Items"
  end

  test "mount view for show item", %{conn: conn, job_id: job_id, item_id: item_id} do
    {:ok, view, html} = live(conn, "/jobs/#{job_id}/items/#{item_id}")
    assert CrawlyUIWeb.ItemLive = view.module
    assert html =~ "Item viewer"
  end

  test "update item view if job is in new state", %{conn: conn} do
    %{id: job_id} = insert_job(%{inserted_at: inserted_at(6 * 60), state: "new"})

    {:ok, view, _html} = live(conn, "/jobs/#{job_id}/items")

    Process.sleep(110)

    assert render(view) =~ "Items"

    Process.sleep(1000)

    assert render(view) =~ "Items"
  end

  test "Update item view if job is in running state", %{
    conn: conn,
    job_id: job_id,
    item_id: item_id
  } do
    item = CrawlyUI.Manager.get_item!(item_id)

    {:ok, view, _html} = live(conn, "/jobs/#{job_id}/items")

    assert render(view) =~ "Discovery time: #{item.inserted_at}"

    # first update is 100 ms
    Process.sleep(50)

    item_2 = insert_item(job_id)

    Process.sleep(90)

    assert render(view) =~ "Discovery time: #{item_2.inserted_at}"

    # from the second update, it's 1s
    Process.sleep(500)

    item_3 = insert_item(job_id)

    Process.sleep(500)

    assert render(view) =~ "Discovery time: #{item_3.inserted_at}"
  end

  test "handle empty search string", %{conn: conn, job_id: job_id} do
    {:ok, _view, html} = live(conn, "/jobs/#{job_id}/items?search=")

    assert html =~
             "<input type=\"text\" placeholder=\"Search\" name=\"search\" autocomplete=\"off\"/>"
  end

  test "handle valid search string", %{conn: conn, job_id: job_id} do
    {:ok, _view, html} = live(conn, "/jobs/#{job_id}/items?search=location%3ACanada")

    assert html =~
             "<input type=\"text\" value=\"location:Canada\" name=\"search\" autocomplete=\"off\"/>"
  end

  test "update view with search result", %{conn: conn, job_id: job_id, item_id: item_id} do
    search_item = insert_item(job_id, inserted_at(0), %{"location" => "Sweden"})

    item = CrawlyUI.Manager.get_item!(item_id)

    {:ok, view, _html} = live(conn, "/jobs/#{job_id}/items")

    render_view = render_submit(view, "search", %{"search" => "location:Sweden"})

    refute render_view =~ "Discovery time: #{item.inserted_at}"
    assert render_view =~ "Discovery time: #{search_item.inserted_at}"
  end

  test "redirect to show item view", %{conn: conn, job_id: job_id, item_id: item_id} do
    {:ok, view, _html} = live(conn, "/jobs/#{job_id}/items")

    item = CrawlyUI.Manager.get_item!(item_id)

    assert render(view) =~ "Discovery time: #{item.inserted_at}"

    render_click(view, :show_item, %{"job" => job_id, "item" => item_id})
    assert_redirect(view, "/jobs/#{job_id}/items/#{item_id}")
  end

  test "redirect to show next item view", %{conn: conn, job_id: job_id, item_id: item_id} do
    {:ok, view, _html} = live(conn, "/jobs/#{job_id}/items/#{item_id}")

    next_item = insert_item(job_id)

    render_click(view, :show_item, %{"job" => job_id, "item" => next_item.id})
    assert_redirect(view, "/jobs/#{job_id}/items/#{next_item.id}")
  end

  test "redirect to show all items view", %{
    conn: conn,
    job_id: job_id,
    item_id: item_id
  } do
    {:ok, view, _html} = live(conn, "/jobs/#{job_id}/items/#{item_id}")

    render_click(view, :job_items, %{"job" => job_id})
    assert_redirect(view, "/jobs/#{job_id}/items")
  end

  test "redirect go to page", %{
    conn: conn,
    job_id: job_id,
    item_id: item_id
  } do
    # page 1
    item_1 = CrawlyUI.Manager.get_item!(item_id)
    Enum.each(1..9, &insert_item(job_id, inserted_at(&1)))

    # page 2
    item_2 = insert_item(job_id)

    Application.put_env(:crawly_ui, :page_size, 1)

    {:ok, view, _html} = live(conn, "/jobs/#{job_id}/items")

    assert render(view) =~ "Discovery time: #{item_2.inserted_at}"
    refute render(view) =~ "Discovery time: #{item_1.inserted_at}"

    {:ok, new_view, _html} =
      view
      |> render_click(:goto_page, %{"page" => "2"})
      |> follow_redirect(conn, "/jobs/#{job_id}/items?page=2&search=")

    refute render(new_view) =~ "Discovery time: #{item_2.inserted_at}"
    assert render(new_view) =~ "Discovery time: #{item_1.inserted_at}"

    Application.put_env(:crawly_ui, :page_size, 10)
  end
end

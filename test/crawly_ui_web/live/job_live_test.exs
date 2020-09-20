defmodule CrawlyUIWeb.JobLiveTest do
  import CrawlyUI.DataCase

  use CrawlyUIWeb.ConnCase
  import Phoenix.LiveViewTest

  test "job view uses liveview when there is no job", %{conn: conn} do
    {:ok, view, html} = live(conn, "/")
    assert CrawlyUIWeb.JobLive = view.module
    assert html =~ "Welcome to Crawly UI"
  end

  test "job view uses liveview when there are jobs", %{conn: conn} do
    insert_job()
    {:ok, _view, html} = live(conn, "/")
    assert html =~ "Jobs"
  end

  test "redirect when click schedule", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    render_click(view, :schedule)
    assert_redirect(view, "/schedule")
  end

  test "redirect when click on job's items", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")
    render_click(view, :job_items, %{"id" => "1"})
    assert_redirect(view, "/jobs/1/items")
  end

  test "update view after 100ms when jobs is updated to running", %{conn: conn} do
    job = insert_job(%{inserted_at: inserted_at(6 * 60), state: "new"})
    insert_job(%{state: "abandoned"})

    {:ok, view, _html} = live(conn, "/")

    assert render(view) =~
             "<td>new</td><td>#{job.inserted_at}</td><td>0 items/min</td><td>0 min</td>"

    Process.sleep(20)

    insert_item(job.id, inserted_at(50))
    insert_item(job.id, inserted_at(10))

    CrawlyUI.Manager.update_job(job, %{state: "running"})

    assert render(view) =~
             "<td>new</td><td>#{job.inserted_at}</td><td>0 items/min</td><td>0 min</td>"

    Process.sleep(100)

    # render after every 100ms

    assert render(view) =~
             "<td>running</td><td>#{job.inserted_at}</td><td>2 items/min</td><td>5 min</td>"

    insert_item(job.id)

    Process.sleep(100)

    assert render(view) =~
             "<td>running</td><td>#{job.inserted_at}</td><td>3 items/min</td><td>6 min</td>"
  end

  test "view not update if no job is running", %{conn: conn} do
    job = insert_job(%{state: "abandoned"})

    {:ok, view, _html} = live(conn, "/")

    assert render(view) =~
             "<td>abandoned</td><td>#{job.inserted_at}</td><td>0 items/min</td><td>0 min</td>"

    Process.sleep(100)

    assert render(view) =~
             "<td>abandoned</td><td>#{job.inserted_at}</td><td>0 items/min</td><td>0 min</td>"
  end

  test "go to page", %{conn: conn} do
    job_1 = insert_job(%{inserted_at: inserted_at(6 * 60)})
    job_2 = insert_job()

    Application.put_env(:crawly_ui, :page_size, 1)

    {:ok, view, _html} = live(conn, "/")

    assert render(view) =~ "<td>#{job_2.inserted_at}</td>"
    refute render(view) =~ "<td>#{job_1.inserted_at}</td>"

    {:ok, new_view, _html} =
      view
      |> render_click(:goto_page, %{"page" => "2"})
      |> follow_redirect(conn, "/?page=2")

    assert render(new_view) =~ "<td>#{job_1.inserted_at}</td>"
    refute render(new_view) =~ "<td>#{job_2.inserted_at}</td>"

    Application.put_env(:crawly_ui, :page_size, 10)
  end
end

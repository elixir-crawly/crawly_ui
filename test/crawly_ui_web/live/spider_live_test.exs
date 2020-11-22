defmodule CrawlyUIWeb.SpiderLiveTest do
  import CrawlyUI.DataCase

  use CrawlyUIWeb.ConnCase
  import Phoenix.LiveViewTest

  import Mock

  test "mount spider view to show all available spider", %{conn: conn} do
    {:ok, _view, html} = live(conn, "/spider")

    assert html =~ "Spiders"
  end

  test "mount spider view for showing all jobs of a spider", %{conn: conn} do
    job_1 = insert_job(%{spider: "TestSpider"})
    job_2 = insert_job(%{spider: "TestSpider"})
    insert_job(%{spider: "OtherSpider"})

    {:ok, _view, html} = live(conn, "/spider?spider=TestSpider")

    assert html =~ "Spider"
    assert html =~ "TestSpider"

    assert html =~ "#{job_1.inserted_at}"
    assert html =~ "#{job_2.inserted_at}"

    refute html =~ "OtherSpider"
  end

  test "redicrect go to page for spider view", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/spider?spider=TestSpider")

    assert view
           |> render_click(:goto_page, %{"page" => "2"})
           |> follow_redirect(conn, "/spider?page=2&spider=TestSpider")
  end

  test "redirect to a spider's jobs", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/spider")
    render_click(view, :show_spider, %{"spider" => "TestSpider"})
    assert_redirect(view, "/spider?spider=TestSpider")
  end

  test "update all spiders view every 1 second", %{conn: conn} do
    with_mock CrawlyUI.SpiderManager, [], list_spiders: fn _ -> ["Crawly.TestSpider"] end do
      # This is a bit weird test as it test the page is refreshed but I can't mock the node list and show the spiders, else we can mock connecting and disconnect to node and the spiders will show and dissappear
      {:ok, view, _html} = live(conn, "/spider")

      assert render(view) =~ "Spiders"
      Process.sleep(1000)
      assert render(view) =~ "Spiders"
      Process.sleep(1000)
      assert render(view) =~ "Spiders"
    end
  end

  test "update job list when view jobs belong to a spider", %{conn: conn} do
    job_1 = insert_job(%{spider: "TestSpider"})

    {:ok, view, _html} = live(conn, "/spider?spider=TestSpider")

    assert render(view) =~ "#{job_1.inserted_at}"

    job_2 = insert_job(%{spider: "TestSpider"})

    Process.sleep(100)

    assert render(view) =~ "#{job_1.inserted_at}"
    assert render(view) =~ "#{job_2.inserted_at}"

    job_3 = insert_job(%{spider: "TestSpider"})

    Process.sleep(100)

    assert render(view) =~ "#{job_1.inserted_at}"
    assert render(view) =~ "#{job_2.inserted_at}"
    assert render(view) =~ "#{job_3.inserted_at}"
  end

  # TODO: I have decreased timeouts so we're not nagging the server with huge
  # number of requests. Need to fix the test.

  #  test "update a spider's jobs view when no jobs are running", %{conn: conn} do
  #    job_1 = insert_job(%{spider: "TestSpider", state: "abandoned"})
  #
  #    {:ok, view, _html} = live(conn, "/spider?spider=TestSpider")
  #
  #    assert render(view) =~ "#{job_1.inserted_at}"
  #
  #    Process.sleep(1)
  #    job_2 = insert_job(%{spider: "TestSpider", state: "cancelled"})
  #    Process.sleep(500)
  #
  #    assert render(view) =~ "#{job_1.inserted_at}"
  #    assert render(view) =~ "#{job_2.inserted_at}"
  #  end

  test "cancel running job", %{conn: conn} do
    job_1 = insert_job(%{state: "running", spider: "TestSpider"})

    with_mock CrawlyUI.SpiderManager, [],
      close_job_spider: fn
        ^job_1 -> {:ok, :stopped}
      end do
      {:ok, view, _html} = live(conn, "/spider?spider=TestSpider")

      assert render(view) =~
               "phx-click=\"cancel\" phx-value-job=\"#{job_1.id}\">Cancel"

      render_click(view, :cancel, %{"job" => Integer.to_string(job_1.id)})

      assert render(view) =~
               "<td>cancelled</td><td>#{job_1.inserted_at}</td><td>0 items/min</td><td>0 min</td><td>"
    end
  end

  test "delete job", %{conn: conn} do
    job_1 = insert_job(%{state: "stopped", spider: "TestSpider"})

    {:ok, view, _html} = live(conn, "/spider?spider=TestSpider")

    assert render(view) =~
             "phx-click=\"delete\" phx-value-job=\"#{job_1.id}\">Delete"

    render_click(view, :delete, %{"job" => Integer.to_string(job_1.id)})

    assert [] == CrawlyUI.Repo.all(CrawlyUI.Manager.Job)

    refute render(view) =~
             "phx-click=\"delete\" phx-value-job=\"#{job_1.id}\">Delete"
  end

  test "redirect to index when a spider job starts successfully", %{conn: conn} do
    with_mock CrawlyUI.SpiderManager, [],
      start_spider: fn
        _, _ -> {:ok, :started}
      end do
      {:ok, view, _html} = live(conn, "/spider")

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
      {:ok, view, _html} = live(conn, "/spider")

      render_click(view, :schedule_spider, %{
        "spider" => "Crawly.TestSpider",
        "node" => "test@node"
      })

      flash = assert_redirect(view, "/spider")

      assert flash["error"] ==
               "{:error, \"Failed\"}"
    end
  end
end

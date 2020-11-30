defmodule CrawlyUIWeb.JobViewTest do
  use CrawlyUIWeb.ConnCase
  import CrawlyUI.DataCase

  import Phoenix.View

  test "render runtime when job run time is nil" do
    job = insert_job(%{run_time: nil})

    assert render_to_string(CrawlyUIWeb.JobView, "show.html",
             total_pages: 1,
             live_action: :index,
             page: 1,
             spider: nil,
             rows: [job]
           ) =~ "-"
  end

  test "render runtime when job run time is less than an hour" do
    job = insert_job(%{run_time: 10})

    assert render_to_string(CrawlyUIWeb.JobView, "show.html",
             total_pages: 1,
             live_action: :index,
             page: 1,
             spider: nil,
             rows: [job]
           ) =~
             "10 min"
  end

  test "render runtime when job run time is more than an hour" do
    job = insert_job(%{run_time: 90})

    assert render_to_string(CrawlyUIWeb.JobView, "show.html",
             total_pages: 1,
             live_action: :index,
             page: 1,
             spider: nil,
             rows: [job]
           ) =~
             "1.5 hours"
  end

  test "render spider name with String input" do
    job_1 = insert_job(%{spider: "Elixir.Spider.Test"})
    job_2 = insert_job(%{spider: "Spider.Test"})
    job_3 = insert_job(%{spider: "Test"})

    view =
      render_to_string(CrawlyUIWeb.JobView, "show.html",
        total_pages: 1,
        live_action: :index,
        page: 1,
        spider: nil,
        rows: [job_1, job_2, job_3]
      )

    assert view =~ ">Test</a>"
    refute view =~ ">Spider.Test</a>"
    refute view =~ ">Elixir.Spider.Test</a>"
  end

  test "render spider name with atom input" do
    view =
      render_to_string(CrawlyUIWeb.JobView, "pick_spider.html",
        node: "test@worker.com",
        generic_spiders: [],
        spiders: [:"Elixir.Spider.Test", :"Spider.Test", :Test],
        error: nil
      )

    assert view =~ "<option value=\"Test\">Test</option>"
    assert view =~ "<option value=\"Spider.Test\">Test</option>"
    assert view =~ "<option value=\"Elixir.Spider.Test\">Test</option>"
  end

  test "render cancel button" do
    job = insert_job(%{spider: "Elixir.Spider.Test", state: "running"})

    assert render_to_string(CrawlyUIWeb.JobView, "show.html",
             total_pages: 1,
             live_action: :index,
             page: 1,
             spider: nil,
             rows: [job]
           ) =~
             "<button data-confirm=\"Do you really want to cancel running spider Test?\" phx-click=cancel phx-value-job=#{
               job.id
             }>Cancel</button></td>"
  end

  test "render delete button" do
    job = insert_job(%{spider: "Elixir.Spider.Test", state: "stopped", items_count: 100})

    assert render_to_string(CrawlyUIWeb.JobView, "show.html",
             total_pages: 1,
             live_action: :index,
             page: 1,
             spider: nil,
             rows: [job]
           ) =~
             "<button data-confirm=\"This will delete this job of spider Test and all 100 item(s). Are you sure?\" phx-click=delete phx-value-job=#{
               job.id
             }>Delete</button>"
  end
end

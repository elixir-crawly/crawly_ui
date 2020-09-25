defmodule CrawlyUIWeb.JobViewTest do
  use CrawlyUIWeb.ConnCase
  import CrawlyUI.DataCase

  import Phoenix.View

  test "render runtime when job run time is nil" do
    job = insert_job(%{run_time: nil})

    assert render_to_string(CrawlyUIWeb.JobView, "index.html",
             total_pages: 1,
             live_action: :index,
             page: 1,
             spider: nil,
             rows: [job]
           ) =~ "-"
  end

  test "render runtime when job run time is less than an hour" do
    job = insert_job(%{run_time: 10})

    assert render_to_string(CrawlyUIWeb.JobView, "index.html",
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

    assert render_to_string(CrawlyUIWeb.JobView, "index.html",
             total_pages: 1,
             live_action: :index,
             page: 1,
             spider: nil,
             rows: [job]
           ) =~
             "1.5 hours"
  end
end

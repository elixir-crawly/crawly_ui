defmodule CrawlyUIWeb.JobViewTest do
  import CrawlyUI.DataCase
  use CrawlyUIWeb.ConnCase

  import Phoenix.View

  test "show crawling speed" do
    params = params(6 * 60)

    assert render_to_string(CrawlyUIWeb.JobView, "index.html", params) =~ "<td>2 items/min</td>"
  end

  test "show runtime when runtime is less than an hour" do
    params = params(6 * 60)

    assert render_to_string(CrawlyUIWeb.JobView, "index.html", params) =~ "<td>5 min</td>"
  end

  test "show runtime when runtime is more than an hour" do
    params = params(62 * 60)

    assert render_to_string(CrawlyUIWeb.JobView, "index.html", params) =~ "<td>1.02 hours</td>"
  end

  test "show runtime as 0 min when runtime is not updated" do
   job = insert_job(%{inserted_at: inserted_at(6*60)})

    insert_item(job.id, inserted_at(50))
    insert_item(job.id, inserted_at(10))

    page = CrawlyUI.Manager.list_jobs(%{})
    params = [jobs: page.entries, page: page, search: nil]

    assert render_to_string(CrawlyUIWeb.JobView, "index.html", params) =~ "<td>0 min</td>"
  end

  defp params(job_inserted_at) do
    job = insert_job(%{inserted_at: inserted_at(job_inserted_at)})

    insert_item(job.id, inserted_at(50))
    insert_item(job.id, inserted_at(10))

    CrawlyUI.Manager.update_all_jobs()

    page = CrawlyUI.Manager.list_jobs(%{})

    [jobs: page.entries, page: page, search: nil]
  end
end

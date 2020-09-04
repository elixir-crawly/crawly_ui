defmodule CrawlyUi.ManagerTest do
  use CrawlyUI.DataCase

  alias CrawlyUI.Repo

  alias CrawlyUI.Manager
  alias CrawlyUI.Manager.Job
  alias CrawlyUI.Manager.Item

  @job_abandoned_timeout 60 * 30 + 10

  describe "update_job_status/0" do
    test "updates job state to abandoned" do
      %{id: job_id_1} = insert_job()
      insert_item(job_id_1, true)

      %{id: job_id_2} = insert_job(%{inserted_at: inserted_at_expired()})

      assert %{state: "running"} = Repo.get(Job, job_id_1)
      assert %{state: "running"} = Repo.get(Job, job_id_2)
      Manager.update_job_status()
      assert %{state: "abandoned"} = Repo.get(Job, job_id_1)
      assert %{state: "abandoned"} = Repo.get(Job, job_id_2)
    end

    test "does not update when job is still running" do
      %{id: job_id_1} = insert_job()
      insert_item(job_id_1)

      %{id: job_id_2} = insert_job(%{inserted_at: inserted_at_valid()})

      assert %{state: "running"} = Repo.get(Job, job_id_1)
      assert %{state: "running"} = Repo.get(Job, job_id_2)
      Manager.update_job_status()
      assert %{state: "running"} = Repo.get(Job, job_id_1)
      assert %{state: "running"} = Repo.get(Job, job_id_2)
    end

    test "when job state is not running, do nothing" do
      %{id: job_id} = insert_job(%{state: "something_else"})
      insert_item(job_id, true)

      assert %{state: "something_else"} = Repo.get(Job, job_id)
      Manager.update_job_status()
      assert %{state: "something_else"} = Repo.get(Job, job_id)
    end
  end

  describe "is_job_abandoned/1" do
    test "job with most recent item passed timeout value is considered abandoned" do
      job = insert_job()
      insert_item(job.id, true)

      assert true == Manager.is_job_abandoned(job)
    end

    test "job with most recent item hasn't pass timeout value is not considered abandoned" do
      job = insert_job()
      insert_item(job.id)

      assert false == Manager.is_job_abandoned(job)
    end

    test "job without item and passed timeout value is considered abandoned" do
      job = insert_job(%{inserted_at: inserted_at_expired()})
      assert true == Manager.is_job_abandoned(job)
    end

    test "job without item and hasn't passed timeout value is not considered abandoned" do
      job = insert_job(%{inserted_at: inserted_at_valid()})
      assert false == Manager.is_job_abandoned(job)
    end
  end

  ## Private function for inserting up jobs and items
  defp insert_job(params \\ %{}) do
    params =
      Map.merge(%{spider: "Crawly", state: "running", tag: "test", node: "crawly@test"}, params)

    Repo.insert!(struct(Job, params))
  end

  defp insert_item(job_id, expired \\ false) do
    inserted_at =
      if expired do
        inserted_at_expired()
      else
        inserted_at_valid()
      end

    Repo.insert!(%Item{job_id: job_id, inserted_at: inserted_at, data: %{}})
  end

  defp inserted_at_valid do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.truncate(:second)
  end

  defp inserted_at_expired do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.add(@job_abandoned_timeout * -1, :second)
    |> NaiveDateTime.truncate(:second)
  end
end

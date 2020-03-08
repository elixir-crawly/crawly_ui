defmodule CrawlyUI.CrawlyUIWebTest do
  use CrawlyUI.DataCase

  alias CrawlyUI.Manager

  describe "jobs" do
    alias CrawlyUI.Manager.Job

    @valid_attrs %{spider: "some spider", state: "some state", tag: "own_spider"}
    @update_attrs %{spider: "some updated spider", state: "some updated state", tag: "own_spider"}
    @invalid_attrs %{spider: nil, state: nil, tag: nil}

    def job_fixture(attrs \\ %{}) do
      {:ok, job} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Manager.create_job()

      job
    end

    test "list_jobs/0 returns all jobs" do
      job = job_fixture()
      assert Manager.list_jobs(%{}).entries == [job]
    end

    test "get_job!/1 returns the job with given id" do
      job = job_fixture()
      assert Manager.get_job!(job.id) == job
    end

    test "create_job/1 with valid data creates a job" do
      assert {:ok, %Job{} = job} = Manager.create_job(@valid_attrs)
      assert job.spider == "some spider"
      assert job.state == "some state"
    end

    test "create_job/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Manager.create_job(@invalid_attrs)
    end

    test "update_job/2 with valid data updates the job" do
      job = job_fixture()
      assert {:ok, %Job{} = job} = Manager.update_job(job, @update_attrs)
      assert job.spider == "some updated spider"
      assert job.state == "some updated state"
    end

    test "update_job/2 with invalid data returns error changeset" do
      job = job_fixture()
      assert {:error, %Ecto.Changeset{}} = Manager.update_job(job, @invalid_attrs)
      assert job == Manager.get_job!(job.id)
    end

    test "delete_job/1 deletes the job" do
      job = job_fixture()
      assert {:ok, %Job{}} = Manager.delete_job(job)
      assert_raise Ecto.NoResultsError, fn -> Manager.get_job!(job.id) end
    end

    test "change_job/1 returns a job changeset" do
      job = job_fixture()
      assert %Ecto.Changeset{} = Manager.change_job(job)
    end
  end
end

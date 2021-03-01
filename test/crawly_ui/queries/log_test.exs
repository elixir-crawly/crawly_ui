defmodule CrawlyUI.Queries.LogTest do
  use CrawlyUI.DataCase

  import Ecto.Query, warn: false

  alias CrawlyUI.Repo

  describe "#paginate" do
    setup do
      [job: insert_job()]
    end

    test "with inserted_at returns logs next to specified", %{job: job} do
      log1 = insert_log(job.id)
      log2 = insert_log(job.id)
      log3 = insert_log(job.id)
      log4 = insert_log(job.id)
      log5 = insert_log(job.id)
      log6 = insert_log(job.id)
      log7 = insert_log(job.id)
      log8 = insert_log(job.id)
      log9 = insert_log(job.id)
      log10 = insert_log(job.id)

      assert CrawlyUI.Queries.Log.paginate(log10, job.id) == [log9, log8, log7, log6, log5]
      assert CrawlyUI.Queries.Log.paginate(log5, job.id) == [log4, log3, log2, log1]
    end

    test "it accepts rows argument", %{job: job} do
      
    end

    test "it accepts filters argument", %{job: job} do

    end
  end
end

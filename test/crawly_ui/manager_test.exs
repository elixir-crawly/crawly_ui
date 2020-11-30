defmodule CrawlyUi.ManagerTest do
  use CrawlyUI.DataCase

  import Ecto.Query, warn: false

  alias CrawlyUI.Repo

  alias CrawlyUI.Manager
  alias CrawlyUI.Manager.Job
  alias CrawlyUI.Manager.Item

  import Mock

  describe "update_job_status/0" do
    test "updates job state" do
      job_1 = insert_job(%{tag: "test_1"})
      insert_item(job_1.id, inserted_at_expired())

      job_2 = insert_job(%{inserted_at: inserted_at_expired()})

      with_mock CrawlyUI.SpiderManager,
        close_job_spider: fn
          ^job_1 -> {:ok, :stopped}
          ^job_2 -> {:error, :spider_not_running}
        end do
        # Job with matching tag means it is running and abandonned, otherwise stopped

        assert %{state: "running"} = Repo.get(Job, job_1.id)
        assert %{state: "running"} = Repo.get(Job, job_2.id)

        Manager.update_job_status()

        assert %{state: "stopped"} = Repo.get(Job, job_1.id)
        assert %{state: "stopped"} = Repo.get(Job, job_2.id)
      end
    end

    #    test "updates job state to node down when calling worker node failed" do
    #      with_mock CrawlyUI.SpiderManager,
    #        close_job_spider: fn _ ->
    #          {:error, :nodedown}
    #        end do
    #        %{id: job_id_1} = insert_job()
    #        insert_item(job_id_1, inserted_at_expired())
    #
    #        assert %{state: "running"} = Repo.get(Job, job_id_1)
    #
    #        Manager.update_job_status()
    #        assert %{state: "node down"} = Repo.get(Job, job_id_1)
    #      end
    #    end

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
      insert_item(job_id, inserted_at_expired())

      assert %{state: "something_else"} = Repo.get(Job, job_id)
      Manager.update_job_status()
      assert %{state: "something_else"} = Repo.get(Job, job_id)
    end
  end

  describe "is_job_abandoned/1" do
    test "job with most recent item passed timeout value is considered abandoned" do
      job = insert_job()
      insert_item(job.id, inserted_at_expired())

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

  test "list_jobs/0 lists all jobs" do
    # job with inserted at shift by 1, 2, 3 seconds so the order is fixed
    [job_1, job_2, job_3] =
      Enum.map([1, 2, 3], fn x -> insert_job(%{inserted_at: inserted_at(x)}) end)

    assert %{entries: [^job_1, ^job_2, ^job_3]} = Manager.list_jobs([])
  end

  test "get_job/1 returns a job" do
    job = insert_job()
    assert job == Manager.get_job!(job.id)
  end

  describe "create_job/1" do
    test "create a job" do
      assert {:ok, %Job{}} =
               Manager.create_job(%{
                 spider: "Crawly",
                 state: "running",
                 tag: "test",
                 node: "crawly@test"
               })
    end

    test "invalid changeset" do
      assert {:error, _} = Manager.create_job()
    end
  end

  describe "update_job/1" do
    test "update a job" do
      job = insert_job()
      job_id = job.id

      assert {:ok, %Job{id: ^job_id, spider: "Crawly 2"}} =
               Manager.update_job(job, %{spider: "Crawly 2"})
    end

    test "invalid change" do
      job = insert_job()

      assert {:error, _} = Manager.update_job(job, %{items_count: -1, spider: :atom_name})
    end
  end

  test "cancell_running_job/1" do
    job_1 = insert_job(%{state: "running"})
    job_2 = insert_job(%{state: "running"})
    job_3 = insert_job(%{state: "running"})

    with_mock CrawlyUI.SpiderManager, [],
      close_job_spider: fn
        ^job_1 -> {:ok, :stopped}
        ^job_2 -> {:error, :spider_not_running}
        ^job_3 -> {:error, :nodedown}
      end do
      job_id_1 = job_1.id
      job_id_2 = job_2.id
      job_id_3 = job_3.id

      assert {:ok, %Job{id: ^job_id_1, state: "cancelled"}} = Manager.cancel_running_job(job_1)
      assert {:ok, %Job{id: ^job_id_2, state: "stopped"}} = Manager.cancel_running_job(job_2)
      assert {:ok, %Job{id: ^job_id_3, state: "node down"}} = Manager.cancel_running_job(job_3)
    end
  end

  test "delete_job/1 sucessfully delete a job" do
    job = insert_job()
    assert {:ok, %Job{}} = Manager.delete_job(job)
    assert nil == Repo.get(Job, job.id)
  end

  test "delete_all_job_items/1 deletes all items belongs to a job" do
    job_1 = insert_job()
    %{id: job_2_id} = insert_job()

    insert_item(job_1.id)
    insert_item(job_1.id)

    insert_item(job_2_id)

    assert Repo.all(Item) |> length() == 3

    Manager.delete_all_job_items(job_1)

    assert [%{job_id: ^job_2_id}] = Repo.all(Item, job_id: job_1.id)
  end

  test "change_job/1" do
    job = insert_job()
    assert %Ecto.Changeset{} = Manager.change_job(job)
  end

  describe "run_time/1" do
    test "when there is no item" do
      job = insert_job()
      assert 0.0 == Manager.run_time(job)
    end

    test "when there is item fetched" do
      # job started at 4 min ago
      job = insert_job(%{inserted_at: inserted_at(4 * 60)})
      # item fetched at 1 min ago
      insert_item(job.id, inserted_at(60))
      assert 3.0 == Manager.run_time(job)
    end
  end

  describe "crawl_speed/1" do
    test "for running job" do
      job = insert_job()

      %{id: job_2} = insert_job()

      # item fetched more than a minute ago
      insert_item(job.id, inserted_at(61))

      # newly fetch item
      insert_item(job.id, inserted_at(50))
      insert_item(job.id, inserted_at(10))

      # item from other job
      insert_item(job_2, inserted_at(10))

      assert 2 == Manager.crawl_speed(job)
    end

    test "not running job and running is not 0" do
      job = insert_job(%{run_time: 4, items_count: 8, state: "cancelled"})
      assert 2 == Manager.crawl_speed(job)
    end

    test "not running job and running is 0" do
      job = insert_job(%{run_time: 0, items_count: 8, state: "cancelled"})
      assert 8 == Manager.crawl_speed(job)
    end
  end

  test "count_items/1" do
    %{id: job_2} = insert_job()
    insert_item(job_2)

    job = insert_job()
    Enum.map(1..10, fn _x -> insert_item(job.id) end)

    assert 10 == Manager.count_items(job)
  end

  test "update_item_counts/1" do
    job_1 = insert_job()
    Enum.map(1..5, fn _x -> insert_item(job_1.id) end)

    job_2 = insert_job()
    Enum.map(1..3, fn _x -> insert_item(job_2.id) end)

    job_3 = insert_job()

    assert %Job{items_count: 0} = Repo.get(Job, job_1.id)
    assert %Job{items_count: 0} = Repo.get(Job, job_2.id)
    assert %Job{items_count: 0} = Repo.get(Job, job_3.id)

    Manager.update_item_counts([job_1, job_2, job_3])

    assert %Job{items_count: 5} = Repo.get(Job, job_1.id)
    assert %Job{items_count: 3} = Repo.get(Job, job_2.id)
    assert %Job{items_count: 0} = Repo.get(Job, job_3.id)
  end

  test "update_crawl_speed/1" do
    job_1 = insert_job(%{inserted_at: inserted_at(6 * 60)})
    Enum.each(0..5, fn x -> insert_item(job_1.id, inserted_at(60 * x)) end)

    job_2 = insert_job(%{inserted_at: inserted_at(4 * 60)})
    Enum.each(0..3, fn _x -> insert_item(job_2.id) end)

    job_3 = insert_job()

    assert %Job{crawl_speed: 0} = Repo.get(Job, job_1.id)
    assert %Job{crawl_speed: 0} = Repo.get(Job, job_2.id)
    assert %Job{crawl_speed: 0} = Repo.get(Job, job_3.id)

    Manager.update_crawl_speeds([job_1, job_2, job_3])

    assert %Job{crawl_speed: 1} = Repo.get(Job, job_1.id)
    assert %Job{crawl_speed: 4} = Repo.get(Job, job_2.id)
    assert %Job{crawl_speed: 0} = Repo.get(Job, job_3.id)
  end

  test "update_run_times/1" do
    job_1 = insert_job(%{inserted_at: inserted_at(6 * 60)})

    Enum.each(1..5, fn x -> insert_item(job_1.id, inserted_at(60 * x)) end)

    job_2 = insert_job()

    assert %Job{run_time: 0} = Repo.get(Job, job_1.id)
    assert %Job{run_time: 0} = Repo.get(Job, job_2.id)

    Manager.update_run_times([job_1, job_2])

    assert %Job{run_time: 5} = Repo.get(Job, job_1.id)
    assert %Job{run_time: 0} = Repo.get(Job, job_2.id)
  end

  test "update_running_jobs/0 only updates running jobs" do
    job_1 = insert_job(%{inserted_at: inserted_at(6 * 60)})
    Enum.each(0..5, fn x -> insert_item(job_1.id, inserted_at(60 * x)) end)

    job_2 = insert_job(%{inserted_at: inserted_at(4 * 60)})
    Enum.each(0..3, fn _x -> insert_item(job_2.id) end)

    job_3 = insert_job()

    job_4 = insert_job(%{state: "abandoned"})
    Enum.each(1..3, fn _x -> insert_item(job_4.id) end)

    assert %Job{items_count: 0, crawl_speed: 0, run_time: 0} = Repo.get(Job, job_1.id)
    assert %Job{items_count: 0, crawl_speed: 0, run_time: 0} = Repo.get(Job, job_2.id)
    assert %Job{items_count: 0, crawl_speed: 0, run_time: 0} = Repo.get(Job, job_3.id)
    assert %Job{items_count: 0, crawl_speed: 0, run_time: 0} = Repo.get(Job, job_4.id)

    Manager.update_running_jobs()

    assert %Job{items_count: 6, crawl_speed: 1, run_time: 6} = Repo.get(Job, job_1.id)
    assert %Job{items_count: 4, crawl_speed: 4, run_time: 4} = Repo.get(Job, job_2.id)
    assert %Job{items_count: 0, crawl_speed: 0, run_time: 0} = Repo.get(Job, job_3.id)
    assert %Job{items_count: 0, crawl_speed: 0, run_time: 0} = Repo.get(Job, job_4.id)
  end

  test "update_all_jobs/1" do
    job_1 = insert_job(%{inserted_at: inserted_at(6 * 60)})
    Enum.each(0..5, fn x -> insert_item(job_1.id, inserted_at(60 * x)) end)

    job_2 = insert_job(%{inserted_at: inserted_at(4 * 60)})
    Enum.each(0..3, fn _x -> insert_item(job_2.id) end)

    job_3 = insert_job()

    job_4 = insert_job(%{state: "abandoned", inserted_at: inserted_at(2 * 60)})
    Enum.each(0..2, fn _x -> insert_item(job_4.id) end)

    assert %Job{items_count: 0, crawl_speed: 0, run_time: 0} = Repo.get(Job, job_1.id)
    assert %Job{items_count: 0, crawl_speed: 0, run_time: 0} = Repo.get(Job, job_2.id)
    assert %Job{items_count: 0, crawl_speed: 0, run_time: 0} = Repo.get(Job, job_3.id)
    assert %Job{items_count: 0, crawl_speed: 0, run_time: 0} = Repo.get(Job, job_4.id)

    Manager.update_all_jobs()

    assert %Job{items_count: 6, crawl_speed: 1, run_time: 6} = Repo.get(Job, job_1.id)
    assert %Job{items_count: 4, crawl_speed: 4, run_time: 4} = Repo.get(Job, job_2.id)
    assert %Job{items_count: 0, crawl_speed: 0, run_time: 0} = Repo.get(Job, job_3.id)
    assert %Job{items_count: 3, crawl_speed: 2, run_time: 2} = Repo.get(Job, job_4.id)
  end

  test "get_job_by_tag/1" do
    %{id: job_id_1} = insert_job(%{tag: "test"})
    insert_job(%{tag: "other"})

    assert %Job{id: ^job_id_1} = Manager.get_job_by_tag("test")
  end

  describe "list_items/1" do
    test "list all items of a job when there is no search params" do
      job = insert_job(%{inserted_at: inserted_at(6 * 60)})
      items = Enum.map(0..5, fn x -> insert_item(job.id, inserted_at(60 * x)) end)

      assert %{entries: ^items} = Manager.list_items(job.id, [])
    end

    test "lists all items of a job when search string doesn't contain :" do
      job = insert_job(%{inserted_at: inserted_at(6 * 60)})
      items = Enum.map(0..5, fn x -> insert_item(job.id, inserted_at(60 * x), %{"id" => x}) end)

      assert %{entries: ^items} = Manager.list_items(job.id, search: "id")
    end

    test "list items matches the valid search string" do
      job = insert_job(%{inserted_at: inserted_at(6 * 60)})
      Enum.map(0..5, fn x -> insert_item(job.id, inserted_at(60 * x), %{"id" => x}) end)

      assert %{entries: [%Item{data: %{"id" => 1}}]} = Manager.list_items(job.id, search: "id:1")
    end

    test "list items when there job has no item" do
      job = insert_job()
      assert %{entries: []} = Manager.list_items(job.id, search: "id:1")
    end

    test "search can filter items" do
      job = insert_job(%{inserted_at: inserted_at(6 * 60)})

      # Inserting items
      insert_item(job.id, inserted_at(60 * 1), %{"id" => 1, "title" => "chair", "color" => "blue"})

      insert_item(job.id, inserted_at(60 * 2), %{"id" => 2, "title" => "chair", "color" => "red"})
      insert_item(job.id, inserted_at(60 * 3), %{"id" => 3, "title" => "sofa", "color" => "red"})

      assert %{entries: [%Item{data: %{"id" => 1}}]} = Manager.list_items(job.id, search: "id:1")

      assert %{entries: [%Item{data: %{"id" => 3}}]} =
               Manager.list_items(job.id, search: "title:sofa")

      assert %{entries: [%Item{data: %{"id" => 2}}]} =
               Manager.list_items(job.id, search: "title:chair && color:red")
    end

    test "search can support wildcards" do
      job = insert_job(%{inserted_at: inserted_at(6 * 60)})

      # Inserting items
      insert_item(job.id, inserted_at(60 * 1), %{"id" => 1, "title" => "chair", "color" => "blue"})

      insert_item(job.id, inserted_at(60 * 2), %{"id" => 2, "title" => "chair2", "color" => "red"})

      insert_item(job.id, inserted_at(60 * 3), %{"id" => 3, "title" => "sofa", "color" => "red"})

      result = Manager.list_items(job.id, search: "title:chair%")
      data = Enum.map(result.entries, fn item -> item.data end)

      assert [%{"title" => "chair"}, %{"title" => "chair2"}] = data
    end
  end

  test "get_item!/1" do
    %{id: job_id} = insert_job()
    item = insert_item(job_id)

    assert item == Manager.get_item!(item.id)
  end

  describe "most_recent_item/1" do
    test "returns most recent item" do
      job = insert_job(%{inserted_at: inserted_at(6 * 60)})
      [item | _] = Enum.map(0..5, fn x -> insert_item(job.id, inserted_at(60 * x)) end)

      assert item == Manager.most_recent_item(job.id)
    end

    test "returns nill if job has no item" do
      job = insert_job()
      assert nil == Manager.most_recent_item(job.id)
    end
  end

  test "next_item/1 returns an item" do
    job = insert_job(%{inserted_at: inserted_at(6 * 60)})
    [item | _] = Enum.map(0..5, fn x -> insert_item(job.id, inserted_at(60 * x)) end)

    assert %Item{id: next_item_id} = Manager.next_item(item)
  end

  describe "create_item/1" do
    test "with valid values" do
      %{id: job_id} = insert_job()

      assert {:ok, %Item{job_id: ^job_id}} =
               Manager.create_item(%{job_id: job_id, data: %{"id" => 1}})
    end

    test "with invalid value" do
      %{id: job_id} = insert_job()

      assert {:error, _} = Manager.create_item(%{job_id: job_id, data: :invalid})
    end

    test "returns error when job doesn't exists" do
      assert {:error, _} = Manager.create_item(%{job_id: 1, data: :invalid})
    end
  end

  describe "update_item/2" do
    test "with valid changes" do
      %{id: job_id} = insert_job()
      item = insert_item(job_id)

      item_id = item.id

      assert {:ok, %Item{id: ^item_id}} = Manager.update_item(item, %{data: %{"id" => 1}})
    end

    test "with invalid change" do
      %{id: job_id} = insert_job()
      item = insert_item(job_id)

      assert {:error, _} = Manager.update_item(item, %{data: :invalid})
    end
  end

  test "delete_item/2 sucessfully delete an item" do
    %{id: job_id} = insert_job()
    item = insert_item(job_id)

    assert {:ok, %Item{}} = Manager.delete_item(item)
    assert nil == Repo.get(Item, item.id)
  end

  test "change_item/1" do
    %{id: job_id} = insert_job()
    item = insert_item(job_id)

    assert %Ecto.Changeset{} = Manager.change_item(item)
  end
end

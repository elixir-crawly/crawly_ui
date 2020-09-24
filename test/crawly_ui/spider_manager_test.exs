defmodule CrawlyUi.SpiderManagerTest do
  use CrawlyUI.DataCase
  import Mock

  alias CrawlyUI.SpiderManager

  describe "start_spider/2" do
    test "start spider and create job" do
      node = "test"
      spider = "Crawly.TestSpider"

      with_mock :rpc, [:unstick],
        call: fn
          _, Crawly.Engine, :start_spider, _ -> :ok
        end do
        assert [] == Repo.all(CrawlyUI.Manager.Job)

        assert SpiderManager.start_spider(node, spider) == {:ok, :started}

        assert Repo.one!(CrawlyUI.Manager.Job, node: node, spider: spider)
      end
    end

    test "error case" do
      node = "test"
      node_2 = "test_2"
      spider = "Crawly.TestSpider"

      with_mock :rpc, [:unstick],
        call: fn
          :test, Crawly.Engine, :start_spider, _ -> {:badrpc, :nodedown}
          :test_2, Crawly.Engine, :start_spider, _ -> {:error, :already_started}
        end do
        assert [] == Repo.all(CrawlyUI.Manager.Job)

        assert SpiderManager.start_spider(node, spider) == {:badrpc, :nodedown}
        assert SpiderManager.start_spider(node_2, spider) == {:error, :already_started}

        assert [] == Repo.all(CrawlyUI.Manager.Job)
      end
    end
  end

  describe "close_spider/1" do
    test "close spider" do
      with_mock :rpc, [:unstick],
        call: fn
          _, Crawly.Engine, :running_spiders, [] ->
            %{
              :Crawly_1 => {:some_pid, "test_1"}
            }

          _, Crawly.Engine, :stop_spider, [:Crawly_1] ->
            :ok
        end do
        job_1 = insert_job(%{spider: "Crawly_1", tag: "test_1"})
        job_2 = insert_job(%{spider: "Crawly_1", tag: "non_existing_tag"})

        assert SpiderManager.close_spider(job_1) == {:ok, :stopped}
        assert SpiderManager.close_spider(job_2) == {:ok, :already_stopped}
      end
    end

    test "node_down" do
      with_mock :rpc, [:unstick],
        call: fn _, Crawly.Engine, :running_spiders, [] ->
          {:badrpc, :nodedown}
        end do
        job_1 = insert_job(%{spider: "Crawly_1", tag: "test_1"})
        assert SpiderManager.close_spider(job_1) == {:ok, :nodedown}
      end
    end
  end

  describe "list_spider/1" do
    test "with atom input" do
      with_mock :rpc, [:unstick],
        call: fn :node, Crawly, :list_spiders, [] -> ["Crawly.TestSpider"] end do
        assert SpiderManager.list_spiders(:node) == ["Crawly.TestSpider"]
      end
    end

    test "with string input" do
      with_mock :rpc, [:unstick],
        call: fn :node, Crawly, :list_spiders, [] -> ["Crawly.TestSpider"] end do
        assert SpiderManager.list_spiders("node") == ["Crawly.TestSpider"]
      end
    end
  end
end

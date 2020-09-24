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

  describe "close_job_spider/1" do
    test "close spider" do
      with_mock :rpc, [:unstick],
        call: fn
          _, Crawly.Engine, :get_crawl_id, [:Crawly_1] ->
            {:ok, "test_1"}

          _, Crawly.Engine, :stop_spider, [:Crawly_1] ->
            :ok
        end do
        job_1 = insert_job(%{spider: "Crawly_1", tag: "test_1"})
        job_2 = insert_job(%{spider: "Crawly_1", tag: "non_existing_tag"})

        assert SpiderManager.close_job_spider(job_1) == {:ok, :stopped}
        assert SpiderManager.close_job_spider(job_2) == {:error, :spider_not_running}

        assert_called(:rpc.call(:crawly@test, Crawly.Engine, :stop_spider, [:Crawly_1]))
      end
    end

    test "node_down" do
      with_mock :rpc, [:unstick],
        call: fn _, Crawly.Engine, :get_crawl_id, [:Crawly_1] ->
          {:badrpc, :nodedown}
        end do
        job_1 = insert_job(%{spider: "Crawly_1", tag: "test_1"})
        assert SpiderManager.close_job_spider(job_1) == {:error, :nodedown}
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

  test "get_spider_id/2" do
    with_mock :rpc, [:unstick],
      call: fn
        _, Crawly.Engine, :get_crawl_id, [:Crawly_1] ->
          {:ok, "test_1"}

        _, Crawly.Engine, :get_crawl_id, [:Crawly_2] ->
          {:badrpc, :nodedown}
      end do
      assert SpiderManager.get_spider_id(:node, :Crawly_1) == {:ok, "test_1"}
      assert SpiderManager.get_spider_id(:node, :Crawly_2) == {:error, :nodedown}
    end
  end

  test "stop_spider/1" do
    with_mock :rpc, [:unstick],
      call: fn _, Crawly.Engine, :stop_spider, [_] ->
        :ok
      end do
      assert :ok == SpiderManager.stop_spider(:node, :Crawly)
    end
  end
end

defmodule CrawlyUITest do
  use CrawlyUI.DataCase
  import Mock

  test "do not store item when there is no job matching job tag" do
    job = insert_job()

    assert {:error, :job_not_found} ==
             CrawlyUI.store_item(
               "TestSpider",
               %{"id" => 1, "field" => "value"},
               "non_existed_tag",
               "spider@test"
             )

    assert nil ==
             CrawlyUI.Repo.get_by(CrawlyUI.Manager.Item, job_id: job.id)
  end

  test "store item for the job" do
    job = insert_job(%{tag: "job_tag"})

    assert :ok ==
             CrawlyUI.store_item(
               "TestSpider",
               %{"id" => 1, "field" => "value"},
               "job_tag",
               "spider@test"
             )

    assert %{data: %{"id" => 1, "field" => "value"}} =
             CrawlyUI.Repo.get_by(CrawlyUI.Manager.Item, job_id: job.id)
  end

  test "list spiders" do
    with_mock :rpc, [:unstick],
      call: fn _, Crawly, :list_spiders, [] -> ["spider_1", "spider_2"] end do
      assert CrawlyUI.list_spiders("spider@test") == ["spider_1", "spider_2"]
    end
  end
end

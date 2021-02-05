defmodule Spiders.ElixirJobs do
  use Crawly.Spider

  def override_settings() do
    ui_node = System.get_env("UI_NODE") || "ui@127.0.0.1"
    ui_node = ui_node |> String.to_atom()

    pipelines = [
      {Crawly.Pipelines.Validate, fields: [:url, :title, :location]},
      {Crawly.Pipelines.DuplicatesFilter, item_id: :title},
      {Crawly.Pipelines.Experimental.SendToUI, ui_node: ui_node},
      Crawly.Pipelines.JSONEncoder,
      {Crawly.Pipelines.WriteToFile, extension: "json", folder: "/tmp"}
    ]

    [
      concurrent_requests_per_domain: 2,
      closespider_itemcount: 1000,
      pipelines: pipelines,
      closespider_timeout: 1
    ]
  end

  @impl Crawly.Spider
  def base_url(), do: "https://elixir-radar.com/jobs"

  @impl Crawly.Spider
  def init() do
    [
      start_urls: [
        "https://elixir-radar.com/jobs"
      ]
    ]
  end

  @impl Crawly.Spider
  def parse_item(response) do
    {:ok, document} = Floki.parse_document(response.body)
    item_blocks = document |> Floki.find(".job-board-job")
    items = Enum.map(item_blocks, &parse_item_block/1)

    # Extracting links
    hrefs = document |> Floki.find("a.pagination__button") |> Floki.attribute("href")
    absolute_urls = Crawly.Utils.build_absolute_urls(hrefs, base_url())
    requests = Crawly.Utils.requests_from_urls(absolute_urls)
    %Crawly.ParsedItem{:items => items, :requests => requests}
  end

  defp parse_item_block(block) do
    %{
      title: block |> Floki.find(".job-board-job-title") |> Floki.text(),
      url:
        block
        |> Floki.find(".job-board-job-title a")
        |> Floki.attribute("href")
        |> List.first(),
      location: block |> Floki.find(".job-board-job-location") |> Floki.text(),
      description: block |> Floki.find(".job-board-job-description") |> Floki.text()
    }
  end
end

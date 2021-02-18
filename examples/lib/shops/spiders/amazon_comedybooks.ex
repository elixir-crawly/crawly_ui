defmodule Spiders.AmazonComedyBooks do
  @moduledoc """
  Spider implementation for website amazon.de.
  """
  
  use Crawly.Spider

  def override_settings() do
    [
      concurrent_requests_per_domain: 2,
      closespider_itemcount: 100
    ]
  end

  @impl Crawly.Spider
  def base_url(), do: "https://www.amazon.de"

  @impl Crawly.Spider
  def init() do
    [
      start_urls: [
        "https://www.amazon.de/s?k=comedy&i=stripbooks&qid=1590089649"
      ]
    ]
  end

  @impl Crawly.Spider
  def parse_item(response) do
    {:ok, document} = Floki.parse_document(response.body)
    item_blocks = document |> Floki.find("div.s-asin")
    items = Enum.map(item_blocks, &parse_item_block/1)

    # Extracting links
    hrefs = document |> Floki.find("ul.a-pagination a") |> Floki.attribute("href")
    absolute_urls = Crawly.Utils.build_absolute_urls(hrefs, base_url())
    requests = Crawly.Utils.requests_from_urls(absolute_urls)
    %Crawly.ParsedItem{:items => items, :requests => requests}
  end

  defp parse_item_block(block) do
    %{
      id: block |> Floki.attribute("data-asin") |> Floki.text(),
      title: block |> Floki.find("span.a-text-normal") |> Floki.text(),
      price: block |> Floki.find(".a-price-whole") |> List.last() |> Floki.text(),
      url:
        block
        |> Floki.find("a.a-link-normal")
        |> Floki.attribute("href")
        |> hd()
        |> Crawly.Utils.build_absolute_url(base_url()),
      image: block |> Floki.find("img") |> Floki.attribute("src") |> hd()
    }
  end
end

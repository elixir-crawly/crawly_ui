defmodule Spiders.Homebase do
  use Crawly.Spider

  @image_folder Application.get_env(:crawly, :image_folder, "/tmp")

  def override_settings() do
    ui_node = System.get_env("UI_NODE") || "ui@127.0.0.1"
    ui_node = ui_node |> String.to_atom()

    pipelines = [
      {Crawly.Pipelines.Validate, fields: [:title, :sku, :price, :image]},
      {Crawly.Pipelines.DuplicatesFilter, item_id: :title},
      {Crawly.Pipelines.Experimental.SendToUI, ui_node: ui_node},
      Crawly.Pipelines.JSONEncoder,
      {Crawly.Pipelines.WriteToFile, extension: "jl", folder: "/tmp"}
    ]

    [
      concurrent_requests_per_domain: 2,
      closespider_itemcount: 1000,
      pipelines: pipelines,
      closespider_timeout: 1
    ]
  end

  @impl Crawly.Spider
  def base_url(), do: "https://www.homebase.co.uk"

  @impl Crawly.Spider
  def init() do
    [
      start_urls: [
        "https://www.homebase.co.uk/our-range/tools/power-tools/drills/corded-drills"
      ]
    ]
  end

  @impl Crawly.Spider
  def parse_item(response) do
    # Parse response body to document
    {:ok, document} = Floki.parse_document(response.body)

    # Extract individual product page URLs
    urls =
      document
      |> Floki.find("a.product-tile2")
      |> Floki.attribute("href")

    # Convert URLs into Requests
    requests =
      urls
      |> Enum.uniq()
      |> Enum.map(&build_absolute_url/1)
      |> Enum.map(&Crawly.Utils.request_from_url/1)

    # Create item (for pages where items exists)
    item = %{
      title: product_title(document),
      sku: product_sku(document),
      price: product_price(document),
      image: product_image(document)
    }

    %Crawly.ParsedItem{:items => [item], :requests => requests}
  end

  defp build_absolute_url(url), do: URI.merge(base_url(), url) |> to_string()

  defp product_title(document) do
    document
    |> Floki.find("div.page-title h1")
    |> Floki.text()
  end

  defp product_sku(document) do
    document
    |> Floki.find(".product-header-heading span.product-in")
    |> Floki.attribute("content")
    |> Floki.text()
  end

  defp product_price(document) do
    document
    |> Floki.find(".price-value [itemprop=priceCurrency]")
    |> Floki.text()
  end

  defp product_image(document) do
    document
    |> Floki.find("div.rsTextSlide:first-child > a.rsImg")
    |> Floki.attribute("href")
    |> Floki.text()
  end
end

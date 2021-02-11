defmodule Spiders.AlloUa do
  use Crawly.Spider

  def override_settings() do
    ui_node = System.get_env("UI_NODE") || "ui@127.0.0.1"
    ui_node = ui_node |> String.to_atom()

    pipelines = [
      {Crawly.Pipelines.Validate, fields: [:title, :description, :price]},
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
  def base_url(), do: "https://allo.ua/ru/"

  @impl Crawly.Spider
  def init() do
    [
      start_urls: [
        "https://allo.ua/ru/products/notebooks/"
      ]
    ]
  end

  @impl Crawly.Spider
  def parse_item(response) do
    # Parse response body to document
    {:ok, document} = Floki.parse_document(response.body)

    next_page =
      document
      |> Floki.find("div.pagination__next a.pagination__next__link")
      |> Floki.attribute("href")
      |> Floki.text()

    # Extract individual product page URLs
    product_pages =
      document
      |> Floki.find("div.product-card__content")
      |> Floki.find("a.product-card__title")
      |> Floki.attribute("href")

    urls = [next_page|product_pages]

    requests =
      urls
      |> Enum.uniq()
      |> Enum.map(&Crawly.Utils.request_from_url/1)

    # Create item (for pages where items exists)
    item = %{
      title: product_title(document),
      description: product_description(document),
      price: product_price(document)
    }

    %Crawly.ParsedItem{items: [item], requests: requests}
  end

  defp product_title(document) do
    document
    |> Floki.find("h1.product-header__title")
    |> Floki.text()
  end

  defp product_description(document) do
    document
    |> Floki.find("td.product-details__value")
    |> Floki.text()
  end

  defp product_price(document) do
    document
    |> Floki.find("div.v-price-box__cur.metric")
    |> Floki.find("span.sum")
    |> Floki.text()
  end
end

defmodule Spiders.Walmart do
  @moduledoc """
  Spider implementation for website walmart.com.
  """

  use Crawly.Spider

  @impl Crawly.Spider
  def base_url(), do: "https://www.walmart.com"

  @impl Crawly.Spider
  def init() do
    [
      start_urls: [
        "https://www.walmart.com/browse/movies-tv-shows/classic-movies",
        "https://www.walmart.com/browse/auto-tires/91083",
        "https://www.walmart.com/cp/auto-body/1074767"
      ]
    ]
  end

  @impl Crawly.Spider
  def parse_item(response) do
    {:ok, document} = Floki.parse_document(response.body)

    item = %{
      id: response.request_url |> String.split("/") |> List.last(),
      title: document |> Floki.find(".prod-ProductTitle") |> Floki.text(),
      price: document |> Floki.find(".price-characteristic") |> Floki.attribute("content"),
      description: document |> Floki.find(".AboutThisItem") |> Floki.text(),
      image: document |> Floki.find(".hover-zoom-hero-image") |> Floki.attribute("src"),
      url: response.request_url
    }

    product_hrefs = document |> Floki.find("a.product-title-link") |> Floki.attribute("href")

    department_hrefs =
      document |> Floki.find(".department-single-level a") |> Floki.attribute("href")

    show_by_category_hrefs =
      document |> Floki.find(".SideBarMenuModuleItem a") |> Floki.attribute("href")

    pagination_hrefs = document |> Floki.find("link[rel=next]") |> Floki.attribute("href")

    hrefs = product_hrefs ++ department_hrefs ++ show_by_category_hrefs ++ pagination_hrefs
    absolute_urls = Crawly.Utils.build_absolute_urls(hrefs, base_url())
    requests = Crawly.Utils.requests_from_urls(absolute_urls)

    %Crawly.ParsedItem{:items => [item], :requests => requests}
  end
end

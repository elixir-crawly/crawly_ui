defmodule CrawlyUIWeb.LogController do
  use CrawlyUIWeb, :controller

  @items_per_page 50

  alias CrawlyUI.Queries.Log

  def index(conn, %{"job_id" => id} = params) do
    page = Map.get(params, "page", "0") |> String.to_integer()
    limit = Map.get(params, "limit", @items_per_page)

    filter = Map.get(params, "logs_filter", "all")
    filters = ["requests", "items", "workers", "manager"]
    total_pages = round(Log.count_logs(id, filter) / @items_per_page)
    items = Log.list_logs(id, %{page: page, limit: limit}, filter)

    render(conn, "index.html",
      id: id,
      extra_params: "logs_filter=#{filter}",
      current_filter: filter,
      filters: filters,
      current_page: page,
      total_pages: total_pages,
      items: items
    )
  end
end

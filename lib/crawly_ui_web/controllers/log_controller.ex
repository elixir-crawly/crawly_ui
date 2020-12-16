defmodule CrawlyUIWeb.LogController do
  use CrawlyUIWeb, :controller

  alias CrawlyUI.Manager

  def index(conn, %{"job_id" => id} = params) do
    filter = Map.get(params, "logs_filter", "all")
    filters = ["requests", "items", "workers", "manager"]
    page = Manager.list_logs(id, params, filter)

    render(conn, "index.html",
      id: id,
      extra_params: "logs_filter=#{filter}",
      current_filter: filter,
      filters: filters,
      current_page: page.page_number,
      items: page.entries,
      page: page,
      total_pages: page.total_pages
    )
  end
end

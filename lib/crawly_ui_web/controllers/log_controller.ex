defmodule CrawlyUIWeb.LogController do
  use CrawlyUIWeb, :controller

  alias CrawlyUI.Manager

  def index(conn, %{"job_id" => id} = params) do
    page = Manager.list_logs(id, params)

    render(conn, "index.html",
      id: id,
      current_page: page.page_number,
      items: page.entries,
      page: page,
      total_pages: page.total_pages
    )
  end
end

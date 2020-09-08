defmodule CrawlyUIWeb.ItemController do
  use CrawlyUIWeb, :controller

  alias CrawlyUI.Manager

  def index(conn, %{"job_id" => id} = params) do
    items = Manager.list_items(id, params)

    search =
      case Map.get(params, "search") do
        nil ->
          nil

        "" ->
          nil

        search ->
          search
      end

    render(conn, "index.html", items: items, search: search)
  end

  def show(conn, %{"id" => id} = _params) do
    item = Manager.get_item!(id)
    next_item = Manager.next_item(item)
    render(conn, "show.html", item: item, next_item: next_item)
  end
end

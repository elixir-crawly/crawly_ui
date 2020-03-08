defmodule CrawlyUIWeb.JobController do
  use CrawlyUIWeb, :controller

  alias CrawlyUI.Manager

  def index(conn, params) do
    page = Manager.list_jobs(params)
    render(conn, "index.html", jobs: page.entries, page: page)
  end

  def pick_node(conn, _params) do
    render(conn, "pick_node.html", nodes: Node.list(), error: nil)
  end

  def pick_spider(conn, %{"node" => node}) do
    node = String.to_atom(node)
    spiders = :rpc.call(node, Crawly, :list_spiders, [])
    render(conn, "pick_spider.html", node: node, spiders: spiders, error: nil)
  end

  def schedule(conn, %{"node" => node, "spider" => spider}) do
    spider = String.to_atom(spider)
    node = String.to_atom(node)
    case :rpc.call(node, Crawly.Engine, :start_spider, [spider]) do
      :ok ->
        conn
        |> put_flash(:info, "Spider scheduled successfully. It might take a bit of time before items will appear here...")
        |> redirect(to: "/")

      error ->
        render(conn, "pick_spider.html", node: node, spiders: [Esl, ErlangOrg], error: error)
    end
  end
end

defmodule CrawlyUIWeb.JobController do
  use CrawlyUIWeb, :controller

  alias CrawlyUI.Manager

  def index(conn, params) do
    jobs = Manager.list_jobs(params)
    render(conn, "index.html", jobs: jobs)
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
    spider_atom = String.to_atom(spider)
    node_atom = String.to_atom(node)
    uuid = Ecto.UUID.generate()

    case :rpc.call(node_atom, Crawly.Engine, :start_spider, [spider_atom, uuid]) do
      :ok ->
        {:ok, _} = Manager.create_job(%{spider: spider, tag: uuid, state: "new", node: node})

        conn
        |> put_flash(
          :info,
          "Spider scheduled successfully. It might take a bit of time before items will appear here..."
        )
        |> redirect(to: "/")

      error ->
        conn
        |> put_flash(:error, "#{inspect(error)}")
        |> redirect(to: "/schedule")
    end
  end
end

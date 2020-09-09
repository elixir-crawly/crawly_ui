defmodule CrawlyUIWeb.ScheduleLive do
  use Phoenix.LiveView

  def render(%{template: template} = assigns) do
    CrawlyUIWeb.JobView.render(template, assigns)
  end

  def mount(_param, %{"nodes" => nodes}, socket) do
    if connected?(socket), do: Process.send_after(self(), :pick_node, 100)

    {:ok, assign(socket, template: "pick_node.html", nodes: nodes)}
  end

  def mount(_param, %{"node" => node, "error" => error}, socket) do
    if connected?(socket), do: Process.send_after(self(), :pick_spider, 1000)

    node = String.to_atom(node)
    spiders = :rpc.call(node, Crawly, :list_spiders, [])

    {:ok,
     assign(socket, template: "pick_spider.html", node: node, spiders: spiders, error: error)}
  end

  def handle_info(:pick_node, socket) do
    nodes = Node.list()
    if connected?(socket), do: Process.send_after(self(), :pick_node, 1000)
    {:noreply, assign(socket, nodes: nodes)}
  end

  def handle_info(:pick_spider, socket) do
    if connected?(socket), do: Process.send_after(self(), :pick_spider, 1000)

    node = socket.assigns.node
    spiders = :rpc.call(node, Crawly, :list_spiders, [])

    {:noreply, assign(socket, spiders: spiders)}
  end

  def handle_event("spider_picked", %{"node" => node}, socket) do
    {:noreply,
     redirect(socket, to: CrawlyUIWeb.Router.Helpers.job_path(socket, :pick_spider, node: node))}
  end

  def handle_event("schedule_spider", %{"spider" => spider}, socket) do
    node_atom = socket.assigns.node
    spider_atom = String.to_atom(spider)

    node = to_string(node_atom)

    uuid = Ecto.UUID.generate()

    case :rpc.call(node_atom, Crawly.Engine, :start_spider, [spider_atom, uuid]) do
      :ok ->
        {:ok, _} =
          CrawlyUI.Manager.create_job(%{spider: spider, tag: uuid, state: "new", node: node})

        info =
          "Spider scheduled successfully. It might take a bit of time before items will appear here..."

        {:noreply,
         socket
         |> put_flash(
           :info,
           info
         )
         |> push_redirect(to: "/")}

      error ->
        {:noreply,
         socket |> put_flash(:error, "#{inspect(error)}") |> push_redirect(to: "/schedule")}
    end
  end
end

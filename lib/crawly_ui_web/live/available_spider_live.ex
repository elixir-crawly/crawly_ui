defmodule CrawlyUIWeb.AvailableSpiderLive do
  use Phoenix.LiveView, layout: {CrawlyUIWeb.LayoutView, "live.html"}

  alias CrawlyUI.SpiderManager
  require Logger

  def render(assigns) do
    CrawlyUIWeb.JobView.render("available_spider.html", assigns)
  end

  def mount(_params, _session, socket) do
    socket = socket |> update_available_spiders()

    if connected?(socket), do: Process.send_after(self(), :update_available_spiders, 10_000)

    {:ok, socket}
  end

  def handle_info(:update_available_spiders, socket) do
    socket = update_available_spiders(socket)

    {:noreply, socket}
  end

  def handle_event("schedule_spider", %{"node" => ""}, socket) do
    {:noreply, socket}
  end

  def handle_event("schedule_spider", %{"node" => node_name, "spider" => spider_name}, socket) do
    case SpiderManager.start_spider(node_name, spider_name) do
      {:ok, :started} ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           "Spider scheduled successfully. It might take a bit of time before items will appear here..."
         )
         |> redirect(to: CrawlyUIWeb.Router.Helpers.job_path(socket, :index))}

      error ->
        {:noreply,
         socket
         |> put_flash(:error, "#{inspect(error)}")
         |> redirect(to: CrawlyUIWeb.Router.Helpers.available_spider_path(socket, :available_spider))}
    end
  end

  def handle_event("pick_node", %{"node" => node_name}, socket) do
    socket = socket |> assign(:current_node, node_name) |> update_available_spiders()

    {:noreply, socket}
  end

  defp update_available_spiders(socket) do
    nodes = Node.list()

    case nodes do
      [] -> assign(socket, available_spiders: [], nodes: [], current_node: nil)
      [_node] -> filter_spiders(nodes, socket)
    end
  end

  defp filter_spiders(nodes, socket) do
    available_spiders = Enum.reduce(nodes, %{}, fn node_name, acc ->
      spiders = SpiderManager.list_spiders(node_name)
      Map.put(acc, node_name, spiders)
    end)

    {node_name, node_spiders} =
      case Map.get(socket.assigns, :current_node, nil) do
        nil ->
          {node_name, spiders} = available_spiders |> Enum.at(0)
        name ->
          spiders_for_node = Map.get(available_spiders, name)

          {name, spiders_for_node}
      end

    assign(socket, available_spiders: node_spiders, nodes: nodes, current_node: node_name)
  end
end

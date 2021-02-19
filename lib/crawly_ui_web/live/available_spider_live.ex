defmodule CrawlyUIWeb.AvailableSpiderLive do
    @moduledoc """
  Live view module to display a list of coded (opposite to visual) spiders from all nodes.
  """
  use Phoenix.LiveView, layout: {CrawlyUIWeb.LayoutView, "live.html"}

  alias CrawlyUI.SpiderManager
  require Logger

  def render(assigns) do
    CrawlyUIWeb.JobView.render("available_spider.html", assigns)
  end

  def mount(_params, _session, socket) do
    socket = socket |> assign(:nodes, Node.list()) |> update_available_spiders()

    {:ok, socket}
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
         |> redirect(
           to: CrawlyUIWeb.Router.Helpers.available_spider_path(socket, :available_spider)
         )}
    end
  end

  def handle_event("pick_node", %{"node" => node_name}, socket) do
    socket = socket |> assign(:current_node, node_name) |> show_spiders_for_current_node()

    {:noreply, socket}
  end

  def handle_event("show_spider", %{"spider" => spider}, socket) do
    {:noreply,
     push_redirect(socket,
       to: CrawlyUIWeb.Router.Helpers.spider_path(socket, :spider, spider: spider)
     )}
  end

  defp show_spiders_for_current_node(socket) do
    # Show available spiders for current node
    node_name = Map.get(socket.assigns, :current_node, socket.assigns.nodes |> List.first())
    available_spiders = SpiderManager.list_spiders(node_name)

    assign(socket, available_spiders: available_spiders, current_node: node_name)
  end

  defp update_available_spiders(socket) do
    case Map.get(socket.assigns, :nodes, []) do
      [] -> assign(socket, available_spiders: [], nodes: [], current_node: nil)
      _ -> show_spiders_for_current_node(socket)
    end
  end
end

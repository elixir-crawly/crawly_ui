defmodule CrawlyUIWeb.SpidersLive do
  @moduledoc """
  Live view module to display a list visual spiders created by the user.
  """

  use Phoenix.LiveView, layout: {CrawlyUIWeb.LayoutView, "live.html"}
  alias CrawlyUI.Manager
  require Logger

  def render(assigns) do
    CrawlyUIWeb.JobView.render("spiders.html", assigns)
  end

  def mount(params, _session, socket) do
    page = Map.get(params, "page", 1)

    socket =
      socket
      |> assign(page: page)
      |> update_spiders()

    {:ok, socket}
  end

  def handle_event("goto_page", %{"page" => page}, socket) do
    {:noreply,
     push_redirect(socket,
       to: CrawlyUIWeb.Router.Helpers.spiders_path(socket, :spiders, page: page)
     )}
  end

  def handle_event("schedule_autospider", %{"node" => ""}, socket) do
    {:noreply, socket}
  end

  def handle_event("show_spider", %{"spider" => spider}, socket) do
    {:noreply,
     push_redirect(socket,
       to: CrawlyUIWeb.Router.Helpers.spider_path(socket, :spider, spider: spider)
     )}
  end

  def handle_event("edit_spider", %{"spider" => spider}, socket) do
    {:noreply,
     push_redirect(socket,
       to: "/spider/new?spider=#{spider}"
     )}
  end

  def handle_event("schedule_autospider", %{"node" => node_name, "spider" => spider_name}, socket) do
    CrawlyUI.create_spider(node_name, spider_name)

    case CrawlyUI.SpiderManager.start_spider(node_name, spider_name) do
      {:ok, :started} ->
        Logger.info("Started")

        socket =
          socket
          |> put_flash(:info, "Spider was scheduled")
          |> redirect(to: CrawlyUIWeb.Router.Helpers.job_path(socket, :index))

        {:noreply, socket}

      {:error, reason} ->
        Logger.error("Was unable to start spider: #{inspect(reason)}")

        socket =
          socket
          |> put_flash(:error, "Was unable to start spider: #{inspect(reason)}")

        {:noreply, socket}
    end
  end

  def update_spiders(socket) do
    %{
      total_pages: total_pages,
      page_number: page_number,
      entries: entries
    } = Manager.list_spiders(page_size: 10, page: socket.assigns.page)

    assign(socket,
      rows: Enum.map(entries, fn spider -> spider.name end),
      total_pages: total_pages,
      page: page_number,
      nodes: Node.list()
    )
  end
end

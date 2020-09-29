defmodule CrawlyUIWeb.SpiderLive do
  use Phoenix.LiveView

  alias CrawlyUI.Manager
  alias CrawlyUI.SpiderManager

  import Ecto.Query

  def render(assigns) do
    CrawlyUIWeb.JobView.render("spider.html", assigns)
  end

  def mount(params, _session, socket) do
    spider = Map.get(params, "spider", nil)

    socket =
      case spider do
        nil ->
          # Show a view that lists all available spiders
          if connected?(socket), do: Process.send_after(self(), :update_spiders, 1000)

          socket
          |> assign(spider: spider)
          |> update_spiders()

        spider ->
          # Show all jobs that run on a spider
          page = Map.get(params, "page", 1)

          if connected?(socket), do: Process.send_after(self(), :update_job, 100)

          socket
          |> assign(page: page, spider: spider)
          |> update_job()
      end

    {:ok, socket}
  end

  def handle_info(:update_spiders, socket) do
    socket = update_spiders(socket)
    if connected?(socket), do: Process.send_after(self(), :update_spiders, 1000)
    {:noreply, socket}
  end

  def handle_info(:update_job, socket) do
    socket = update_job(socket)

    if Enum.any?(socket.assigns.rows, &(&1.state == "running")) do
      if connected?(socket), do: Process.send_after(self(), :update_job, 100)
    else
      if connected?(socket), do: Process.send_after(self(), :update_job, 1000)
    end

    {:noreply, socket}
  end

  def handle_event("goto_page", %{"page" => page}, socket) do
    spider = socket.assigns.spider

    {:noreply,
     push_redirect(socket,
       to: CrawlyUIWeb.Router.Helpers.spider_path(socket, :spider, page: page, spider: spider)
     )}
  end

  def handle_event("show_spider", %{"spider" => spider}, socket) do
    {:noreply,
     push_redirect(socket,
       to: CrawlyUIWeb.Router.Helpers.spider_path(socket, :spider, spider: spider)
     )}
  end

  def handle_event("cancel", %{"job" => job_id}, socket) do
    job = job_id |> String.to_integer() |> Manager.get_job!()

    Manager.cancel_running_job(job)

    socket = update_job(socket)

    {:noreply, socket}
  end

  def handle_event("delete", %{"job" => job_id}, socket) do
    job = job_id |> String.to_integer() |> Manager.get_job!()

    job |> Manager.delete_all_job_items()
    {:ok, _} = job |> Manager.delete_job()

    socket = update_job(socket)

    {:noreply, socket}
  end

  def handle_event("schedule_spider", %{"spider" => spider, "node" => node}, socket) do
    case SpiderManager.start_spider(node, spider) do
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
         |> redirect(to: CrawlyUIWeb.Router.Helpers.spider_path(socket, :spider))}
    end
  end

  defp update_spiders(socket) do
    # Update the socket for all spider view
    spider = socket.assigns.spider
    nodes = Node.list()

    available_spiders =
      Enum.map(nodes, fn node ->
        spiders = SpiderManager.list_spiders(node)
        {node, spiders}
      end)

    assign(socket, spider: spider, available_spiders: available_spiders)
  end

  defp update_job(socket) do
    # Update the socket for viewing jobs from a spider, reassign the page because page_number from Scrivener.Pagination is always an integer
    page = socket.assigns.page
    spider = socket.assigns.spider

    %{
      entries: rows,
      page_number: page_number,
      total_pages: total_pages
    } = list_jobs(spider, page)

    assign(socket, rows: rows, total_pages: total_pages, page: page_number)
  end

  defp list_jobs(spider, page) do
    # For a spcific spider
    Manager.Job
    |> where([j], j.spider == ^spider)
    |> Manager.list_jobs(page: page)
  end
end

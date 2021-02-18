defmodule CrawlyUIWeb.SpiderLive do
  @moduledoc """
  Live view module to display available spiders.
  """

  use Phoenix.LiveView, layout: {CrawlyUIWeb.LayoutView, "live.html"}

  alias CrawlyUI.Manager

  import Ecto.Query
  require Logger

  def render(assigns) do
    CrawlyUIWeb.JobView.render("spider.html", assigns)
  end

  def mount(params, _session, socket) do
    spider = Map.get(params, "spider", nil)

    socket =
      case spider do
        nil ->
          socket

        spider ->
          # Show all jobs that run on a spider
          page = Map.get(params, "page", 1)

          if connected?(socket), do: Process.send_after(self(), :update_job, 10_000)

          socket
          |> assign(page: page, spider: spider, nodes: Node.list())
          |> update_job()
      end

    {:ok, socket}
  end

  def handle_params(%{"spider" => nil} = _params, _uri, socket) do
    {:noreply,
     push_redirect(socket,
       to: CrawlyUIWeb.Router.Helpers.spiders_path(socket, :spiders)
     )}
  end

  def handle_params(%{"spider" => _spider} = _params, _url, socket) do
    {:noreply, socket}
  end

  def handle_params(%{} = _params, _uri, socket) do
    {:noreply,
     push_redirect(socket,
       to: CrawlyUIWeb.Router.Helpers.spiders_path(socket, :spiders)
     )}
  end

  def handle_info(:update_job, socket) do
    socket = update_job(socket)

    if Enum.any?(socket.assigns.rows, &(&1.state == "running")) do
      if connected?(socket), do: Process.send_after(self(), :update_job, 10_000)
    else
      if connected?(socket), do: Process.send_after(self(), :update_job, 10_000)
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
    # For a specific spider
    Manager.Job
    |> where([j], j.spider == ^spider)
    |> Manager.list_jobs(page: page)
  end
end

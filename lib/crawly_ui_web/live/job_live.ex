defmodule CrawlyUIWeb.JobLive do
  use Phoenix.LiveView

  alias CrawlyUI.Manager
  alias CrawlyUI.SpiderManager

  import Ecto.Query

  def render(assigns) do
    CrawlyUIWeb.JobView.render("index.html", assigns)
  end

  def mount(params, _session, socket) do
    page = Map.get(params, "page", 1)
    spider = Map.get(params, "spider", nil)

    %{
      entries: rows,
      page_number: page_number,
      total_pages: total_pages
    } = list_jobs(socket.assigns.live_action, spider, page: page)

    socket =
      assign(socket, rows: rows, spider: spider, page: page_number, total_pages: total_pages)

    live_update(socket, :update_job, 100)

    {:ok, socket}
  end

  def handle_info(:update_job, socket) do
    # If any of the jobs are running or in new state then we should keep updating
    # every 100ms else, refresh every second
    Manager.update_job_status()
    Manager.update_running_jobs()

    socket = update_socket(socket)

    if Enum.any?(socket.assigns.rows, &(&1.state == "running")) do
      live_update(socket, :update_job, 100)
    else
      live_update(socket, :update_job, 1000)
    end

    {:noreply, socket}
  end

  def handle_event("schedule", _, socket) do
    {:noreply, push_redirect(socket, to: "/schedule")}
  end

  def handle_event("job_items", %{"id" => job_id}, socket) do
    {:noreply,
     push_redirect(socket, to: CrawlyUIWeb.Router.Helpers.item_path(socket, :index, job_id))}
  end

  def handle_event("list_all_jobs", _, socket) do
    {:noreply, push_redirect(socket, to: "/all")}
  end

  def handle_event("goto_page", %{"page" => page}, socket) do
    live_action = socket.assigns.live_action

    if live_action == :spider do
      spider = socket.assigns.spider

      {:noreply,
       push_redirect(socket,
         to: CrawlyUIWeb.Router.Helpers.job_path(socket, live_action, page: page, spider: spider)
       )}
    else
      {:noreply,
       push_redirect(socket,
         to: CrawlyUIWeb.Router.Helpers.job_path(socket, live_action, page: page)
       )}
    end
  end

  def handle_event("show_spider", %{"spider" => spider}, socket) do
    {:noreply,
     push_redirect(socket,
       to: CrawlyUIWeb.Router.Helpers.job_path(socket, :spider, spider: spider)
     )}
  end

  def handle_event("cancel", %{"job" => job_id}, socket) do
    job = job_id |> String.to_integer() |> Manager.get_job!()

    state =
      case SpiderManager.close_job_spider(job) do
        {:ok, :stopped} ->
          "cancelled"

        {:error, :nodedown} ->
          "node down"

        _ ->
          "stopped"
      end

    Manager.update_job(job, %{state: state})

    socket = update_socket(socket)

    {:noreply, socket}
  end

  def handle_event("delete", %{"job" => job_id}, socket) do
    job = job_id |> String.to_integer() |> Manager.get_job!()

    job |> Manager.delete_all_job_items()
    {:ok, _} = job |> Manager.delete_job()

    socket = update_socket(socket)

    {:noreply, socket}
  end

  defp update_socket(socket) do
    page = socket.assigns.page
    spider = socket.assigns.spider

    %{
      entries: rows,
      total_pages: total_pages
    } = list_jobs(socket.assigns.live_action, spider, page: page)

    assign(socket, rows: rows, total_pages: total_pages)
  end

  defp live_update(socket, state, time) do
    if connected?(socket), do: Process.send_after(self(), state, time)
  end

  defp list_jobs(:index, _, params), do: Manager.list_running_jobs(params)
  defp list_jobs(:show, _, params), do: Manager.list_jobs(params)

  defp list_jobs(:spider, spider, params) do
    Manager.Job
    |> where([j], j.spider == ^spider)
    |> Manager.list_jobs(params)
  end
end

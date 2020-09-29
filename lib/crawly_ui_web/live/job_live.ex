defmodule CrawlyUIWeb.JobLive do
  use Phoenix.LiveView

  alias CrawlyUI.Manager

  def render(assigns) do
    template = template(assigns.live_action)

    CrawlyUIWeb.JobView.render(template, assigns)
  end

  def mount(params, _session, socket) do
    # TODO: This kills prod :( as query seems to be very heavy
    # Manager.update_all_jobs()

    page = Map.get(params, "page", 1)

    socket =
      socket
      |> assign(page: page)
      |> update_socket()

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

    {:noreply,
     push_redirect(socket,
       to: CrawlyUIWeb.Router.Helpers.job_path(socket, live_action, page: page)
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

    %{
      entries: rows,
      page_number: page_number,
      total_pages: total_pages
    } = list_jobs(socket.assigns.live_action, page)

    case socket.assigns.live_action do
      :index ->
        %{entries: recent_rows} = Manager.list_recent_jobs()

        assign(socket,
          rows: rows,
          page: page_number,
          total_pages: total_pages,
          recent_rows: recent_rows
        )

      _ ->
        assign(socket, rows: rows, total_pages: total_pages, page: page_number)
    end
  end

  defp live_update(socket, state, time) do
    if connected?(socket), do: Process.send_after(self(), state, time)
  end

  # List only running jobs and limit for page size of 5 for index, else list all jobs and default page size for all jobs view
  defp list_jobs(:index, page), do: Manager.list_running_jobs(page: page, page_size: 5)
  defp list_jobs(:show, page), do: Manager.list_jobs(page: page)

  defp template(:index), do: "index.html"
  defp template(:show), do: "show.html"
end

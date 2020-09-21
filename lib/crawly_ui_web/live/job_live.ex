defmodule CrawlyUIWeb.JobLive do
  use Phoenix.LiveView

  alias CrawlyUI.Manager

  import CrawlyUIWeb.PaginationHelpers

  def render(assigns) do
    CrawlyUIWeb.JobView.render("index.html", assigns)
  end

  def mount(params, _session, socket) do
    jobs = list_jobs(socket.assigns.live_action)

    page = Map.get(params, "page", "1") |> String.to_integer()

    rows = paginate(jobs, page)

    live_update(socket, :update_job, 100)
    {:ok, assign(socket, jobs: jobs, page: page, rows: rows)}
  end

  def handle_info(:update_job, socket) do
    # If any of the jobs are running or in new state then we should keep updating
    # every 100ms else, refresh every second
    Manager.update_job_status()
    Manager.update_running_jobs()

    jobs = list_jobs(socket.assigns.live_action)
    page = socket.assigns.page
    rows = paginate(jobs, page)

    if Enum.any?(jobs, &(&1.state == "running")) do
      live_update(socket, :update_job, 100)
    else
      live_update(socket, :update_job, 1000)
    end

    {:noreply, assign(socket, jobs: jobs, rows: rows)}
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
    {:noreply,
     push_redirect(socket, to: CrawlyUIWeb.Router.Helpers.job_path(socket, :index, page: page))}
  end

  defp live_update(socket, state, time) do
    if connected?(socket), do: Process.send_after(self(), state, time)
  end

  defp list_jobs(:index), do: Manager.list_running_jobs()
  defp list_jobs(_), do: Manager.list_jobs()
end

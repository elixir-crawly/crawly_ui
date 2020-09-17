defmodule CrawlyUIWeb.JobLive do
  use Phoenix.LiveView, layout: {CrawlyUIWeb.LayoutView, "live.html"}

  alias CrawlyUI.Manager

  def render(assigns) do
    CrawlyUIWeb.JobView.render("index.html", assigns)
  end

  def mount(_params, _session, socket) do
    live_update(socket, :update_job, 100)
    jobs = Manager.list_jobs()
    {:ok, assign(socket, jobs: jobs)}
  end

  def handle_info(:update_job, socket) do
    live_jobs = socket.assigns.jobs

    # If any of the jobs are running or in new state then we should keep updating
    # every 100ms else, refresh every second
    Manager.update_job_status()
    Manager.update_running_jobs()

    if need_update?(live_jobs) do
      live_update(socket, :update_job, 100)
    else
      live_update(socket, :update_job, 1000)
    end

    {:noreply, assign(socket, jobs: Manager.list_jobs())}
  end

  def handle_event("schedule", _, socket) do
    {:noreply, push_redirect(socket, to: "/schedule")}
  end

  def handle_event("job_items", %{"id" => job_id}, socket) do
    job_id = String.to_integer(job_id)

    {:noreply,
     push_redirect(socket, to: CrawlyUIWeb.Router.Helpers.item_path(socket, :index, job_id))}
  end

  defp live_update(socket, state, time) do
    if connected?(socket), do: Process.send_after(self(), state, time)
  end

  defp need_update?([]), do: false
  defp need_update?(jobs), do: Enum.any?(jobs, &(&1.state == "running" or &1.state == "new"))
end

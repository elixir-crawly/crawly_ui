defmodule CrawlyUIWeb.JobLive do
  use Phoenix.LiveView

  alias CrawlyUI.Manager

  def render(%{template: template} = assigns) do
    CrawlyUIWeb.JobView.render(template, assigns)
  end

  def mount(_param, %{"template" => "index.html" = template, "jobs" => jobs}, socket) do
    live_update(socket, :update_job, 1000)

    {:ok, assign(socket, template: template, jobs: jobs)}
  end

  def mount(_param, %{"template" => "pick_node.html" = template, "nodes" => nodes}, socket) do
    live_update(socket, :pick_node, 1000)
    {:ok, assign(socket, template: template, nodes: nodes)}
  end

  def handle_info(:update_job, socket) do
    live_jobs = socket.assigns.jobs

    # If any of the jobs are running or in new state then we should keep updating
    # every 100ms else, refresh every second

    if need_update?(live_jobs) do
      live_update(socket, :update_job, 100)

      Manager.update_job_status()
      Manager.update_running_jobs()
    else
      live_update(socket, :update_job, 1000)
    end

    {:noreply, assign(socket, jobs: Manager.list_jobs())}
  end

  def handle_info(:pick_node, socket) do
    live_update(socket, :pick_node, 1000)
    nodes = Node.list()
    {:noreply, assign(socket, nodes: nodes)}
  end

  defp live_update(socket, state, time) do
    if connected?(socket), do: Process.send_after(self(), state, time)
  end

  defp need_update?([]), do: false
  defp need_update?(jobs), do: Enum.any?(jobs, &(&1.state == "running" or &1.state == "new"))
end

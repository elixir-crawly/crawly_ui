defmodule CrawlyUIWeb.JobLive do
  use Phoenix.LiveView

  alias CrawlyUI.Manager

  @abandon_state "abandoned"

  def render(%{template: template} = assigns) do
    CrawlyUIWeb.JobView.render(template, assigns)
  end

  def mount(_param, %{"template" => "index.html" = template, "jobs" => jobs}, socket) do
    live_update(socket, :update_job, 1000)

    jobs = Enum.map(jobs, &may_update_job/1)

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
    updated_live_jobs =
      if need_update?(live_jobs) do
        live_update(socket, :update_job, 100)
        Enum.map(live_jobs, &may_update_job/1)
      else
        live_update(socket, :update_job, 1000)
        live_jobs
      end

    {:noreply, assign(socket, jobs: updated_live_jobs)}
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

  defp may_update_job(%{id: job_id} = live_job) do
    job = Manager.get_job!(job_id)
    state = get_state(job)

    case state do
      @abandon_state ->
        live_job

      _ ->
        run_time = get_runtime(job)
        crawl_speed = get_crawl_speed(job)
        items_count = get_items_count(job)

        Map.merge(live_job, %{
          run_time: run_time,
          crawl_speed: crawl_speed,
          items_count: items_count,
          state: state
        })
    end
  end

  defp get_state(job) do
    if Manager.is_job_abandoned(job) do
      Manager.update_state(job, @abandon_state)
    end

    Manager.job_state(job)
  end

  defp get_runtime(job) do
    case Manager.run_time(job) do
      result when result > 60 ->
        time_in_hours = (result / 60) |> Float.round(2)
        "#{time_in_hours} hours"

      result ->
        time_in_minutes = result |> Kernel.trunc()
        "#{time_in_minutes} min"
    end
  end

  defp get_crawl_speed(job), do: "#{Manager.crawl_speed(job)} items/min"

  defp get_items_count(job), do: Manager.count_items(job)
end

defmodule CrawlyUIWeb.JobLive do
  use Phoenix.LiveView

  alias CrawlyUI.Manager

  def render(assigns) do
    CrawlyUIWeb.JobView.render("index.html", assigns)
  end

  def mount(_param, %{"jobs" => jobs}, socket) do
    if connected?(socket), do: Process.send_after(self(), :update, 1000)

    jobs =
      for %{id: job_id} <- jobs do
        job = Manager.get_job!(job_id)

        state = get_state(job)
        run_time = get_runtime(job)
        crawl_speed = get_crawl_speed(job)
        items_count = get_items_count(job)

        Map.merge(job, %{
          run_time: run_time,
          crawl_speed: crawl_speed,
          items_count: items_count,
          state: state
        })
      end

    {:ok, assign(socket, jobs: jobs)}
  end

  def handle_info(:update, socket) do
    live_jobs = socket.assigns.jobs

    # If any of the jobs are running or in new state then we should keep updating
    # every 100ms else, refresh every second
    updated_live_jobs =
      if need_update?(live_jobs) do
        if connected?(socket), do: Process.send_after(self(), :update, 100)

        for job <- live_jobs do
          may_update_job(job)
        end
      else
        if connected?(socket), do: Process.send_after(self(), :update, 1000)
        live_jobs
      end

    {:noreply, assign(socket, jobs: updated_live_jobs)}
  end

  defp need_update?([]), do: false

  defp need_update?(jobs) do
    Enum.any?(jobs, &(&1.state == "running" or &1.state == "new"))
  end

  defp may_update_job(%{id: job_id} = live_job) do
    # if job state is "running" then update the fields
    job = Manager.get_job!(job_id)
    state = get_state(job)

    case state do
      "running" ->
        run_time = get_runtime(job)
        crawl_speed = get_crawl_speed(job)
        items_count = get_items_count(job)

        Map.merge(live_job, %{
          run_time: run_time,
          crawl_speed: crawl_speed,
          items_count: items_count,
          state: state
        })

      _ ->
        live_job
    end
  end

  defp get_state(job) do
    case Manager.job_state(job) do
      "running" = state ->
        if Manager.is_job_abandoned(job) do
          "abandoned"
        else
          state
        end

      state ->
        state
    end
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

  defp get_crawl_speed(job) do
    speed = Manager.crawl_speed(job)
    "#{speed} items/min"
  end

  defp get_items_count(job) do
    Manager.count_items(job)
  end
end

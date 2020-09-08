defmodule CrawlyUIWeb.JobView do
  use CrawlyUIWeb, :view

  alias CrawlyUI.Manager.Job

  def get_runtime(job) do
    case job.run_time do
      nil ->
        "0 min"

      result when result > 60 ->
        time_in_hours = (result / 60) |> Float.round(2)
        "#{time_in_hours} hours"

      result ->
        time_in_minutes = result |> Kernel.trunc()
        "#{time_in_minutes} min"
    end
  end

  def get_crawl_speed(%Job{state: state, crawl_speed: speed}) do
    case state do
      "running" -> "#{speed} items/min"
      _ -> "-"
    end
  end

  def get_items_count(job) do
    CrawlyUI.Manager.count_items(job)
  end
end

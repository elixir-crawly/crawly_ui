defmodule CrawlyUIWeb.JobView do
  use CrawlyUIWeb, :view

  def render_run_time(run_time) do
    case run_time do
      nil ->
        "-"

      result when result > 60 ->
        time_in_hours = (result / 60) |> Float.round(2)
        "#{time_in_hours} hours"

      result ->
        time_in_minutes = result |> Kernel.trunc()
        "#{time_in_minutes} min"
    end
  end
end

defmodule CrawlyUIWeb.JobView do
  use CrawlyUIWeb, :view

  @doc """
  Render to display spider name to take the last part of the module. i.e Elixir.Spider.Walmart -> Walmart

  ## Examples

      iex> render_spider_name("Elixir.SPiders.Walmart")
      "Walmart"

       iex> render_spider_name(:"Elixir.SPiders.Walmart")
      "Walmart"

  """
  def render_spider_name(spider) when is_atom(spider) do
    spider |> to_string() |> render_spider_name()
  end

  def render_spider_name(spider) when is_binary(spider) do
    spider
    |> String.split(".")
    |> List.last()
  end

  @doc """
  Convert the spider runtime in hour if it is larger than 60 minutes, else keep the minute scale
  """
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

  @doc """
  Render button template. Cancel for running job and Delete button otherwise
  """
  def render_button(%{state: "running", spider: spider} = job) do
    "<button data-confirm=\"Do you really want to cancel running spider #{
      render_spider_name(spider)
    }?\" phx-click=cancel phx-value-job=#{job.id}>Cancel</button>"
  end

  def render_button(%{spider: spider, items_count: items_count} = job) do
    "<button data-confirm=\"This will delete this job of spider #{render_spider_name(spider)} and all #{
      items_count
    } item(s). Are you sure?\" phx-click=delete phx-value-job=#{job.id}>Delete</button>"
  end

  @doc """
  Render table to display all jobs, one job = one row
  """
  def render_jobs_table(jobs, live_action) do
    """
    <table>
    <thead>
    <tr>
      <th>Spider</th>
      <th>Node</th>
      <th>Items</th>
      <th>Logs</th>
      <th>State</th>

      <th>Start Time</th>
      <th>Crawl Speed</th>
      <th>Crawl time</th>
      <th></th>
    </tr>
    </thead>
    <tbody>
    #{render_row(jobs, live_action)}
    </tbody>
    </table>
    """
  end

  defp render_row(jobs, live_action) do
    for job <- jobs do
      """
      <tr>
        <td>#{render_spider_col(job.spider, live_action)}</td>
        <td>#{job.node}</td>
        <td>
          <a href="/jobs/#{job.id}/items">#{job.items_count}</a>
        </td>
        <td>
          <a href="/logs/#{job.id}/list">logs</a>
        </td>
        <td>#{job.state}</td>
        <td>#{job.inserted_at}</td>
        <td>#{job.crawl_speed} items/min</td>
        <td>#{render_run_time(job.run_time)}</td>
        <td>#{render_button(job)}</td>
      </tr>
      """
    end
  end

  # Show plain text when in spider view otherwise link to spider page
  defp render_spider_col(spider, :spider), do: render_spider_name(spider)

  defp render_spider_col(spider, _) do
    " <a href=\"\" phx-click=\"show_spider\" phx-value-spider=#{spider}>#{
      render_spider_name(spider)
    }</a></td>"
  end
end

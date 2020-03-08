defmodule CrawlyUIWeb.JobView do
  use CrawlyUIWeb, :view
  import Scrivener.HTML

  def get_runtime(job) do
    CrawlyUI.Manager.run_time(job) |> Kernel.trunc()
  end

  def get_items_count(job) do
    CrawlyUI.Manager.count_items(job)
  end
end

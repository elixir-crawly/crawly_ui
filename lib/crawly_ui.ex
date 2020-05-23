defmodule CrawlyUI do
  @moduledoc """
  CrawlyUI keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  alias CrawlyUI.Manager
  require Logger

  def store_item(_spider_name, item, job_tag, _node) do
    case Manager.get_job_by_tag(job_tag) do
      nil ->
        Logger.error("Job was not found: #{job_tag}")
        {:error, :job_not_found}

      job ->
        {:ok, _item} = Manager.create_item(%{job_id: job.id, data: item})
        Manager.update_job(job, %{state: "running"})
        :ok
    end
  end

  def list_spiders(node) do
    :rpc.call(node, Crawly, :list_spiders, [])
  end
end

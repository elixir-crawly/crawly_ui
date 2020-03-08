defmodule CrawlyUI do
  @moduledoc """
  CrawlyUI keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  alias CrawlyUI.Manager

  def store_item(spider_name, item, job_tag, node) do
    job =
      case Manager.get_job_by_tag(job_tag) do
        nil ->
          {:ok, job} = Manager.create_job(%{spider: spider_name, tag: job_tag, state: "running", node: node})
          job

        job ->
          job
      end

    {:ok, _item} = Manager.create_item(%{job_id: job.id, data: item})
  end

  def list_spiders(node) do
    :rpc.call(node, Crawly, :list_spiders, [])
  end

end

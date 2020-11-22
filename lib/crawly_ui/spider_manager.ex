defmodule CrawlyUI.SpiderManager do
  @moduledoc """
  The Spider Manager, makes all the rpcs calls to wokrer node to start, stop or get spider information
  """

  alias CrawlyUI.Manager.Job

  def start_spider(node, spider) when is_binary(node) and is_binary(spider) do
    spider_atom = Module.concat([Elixir, spider])
    node_atom = String.to_atom(node)

    uuid = Ecto.UUID.generate()

    with :ok <- :rpc.call(node_atom, Crawly.Engine, :start_spider, [spider_atom, uuid]),
         {:ok, _} <-
           CrawlyUI.Manager.create_job(%{spider: spider, tag: uuid, state: "new", node: node}) do
      {:ok, :started}
    else
      error -> error
    end
  end

  def close_job_spider(%Job{node: node, spider: spider, tag: tag}) do
    spider = String.to_atom(spider)
    node = String.to_atom(node)

    case get_spider_id(node, spider) do
      {:error, reason} ->
        {:error, reason}

      {:ok, spider_tag} ->
        if spider_tag == tag do
          stop_spider(node, spider)
          {:ok, :stopped}
        else
          {:error, :spider_not_running}
        end
    end
  end

  def list_spiders(node) when is_atom(node) do
    :rpc.call(node, Crawly, :list_spiders, [])
  end

  def list_spiders(node) when is_binary(node) do
    node |> String.to_atom() |> list_spiders()
  end

  def get_spider_id(node, spider) when is_atom(node) and is_atom(spider) do
    case :rpc.call(node, Crawly.Engine, :get_crawl_id, [spider]) do
      {:badrpc, reason} -> {:error, reason}
      reply -> reply
    end
  end

  def stop_spider(node, spider) when is_atom(spider) and is_atom(node) do
    :rpc.call(node, Crawly.Engine, :stop_spider, [spider])
  end
end

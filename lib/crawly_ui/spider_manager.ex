defmodule CrawlyUI.SpiderManager do
  alias CrawlyUI.Manager.Job

  def start_spider(node, spider) when is_binary(node) and is_binary(spider) do
    spider_atom = String.to_atom(spider)
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

  def close_spider(%Job{node: node, spider: spider, tag: tag}) do
    spider = String.to_atom(spider)
    node = String.to_atom(node)

    case running_spiders(node) do
      {:badrpc, _} ->
        {:ok, :nodedown}

      running_spiders when is_map(running_spiders) ->
        {_, spider_tag} = Map.get(running_spiders, spider, {nil, nil})

        if spider_tag == tag do
          stop_spider(node, spider)
          {:ok, :stopped}
        else
          {:ok, :already_stopped}
        end
    end
  end

  def list_spiders(node) when is_atom(node) do
    :rpc.call(node, Crawly, :list_spiders, [])
  end

  def list_spiders(node) when is_binary(node) do
    node |> String.to_atom() |> list_spiders()
  end

  defp running_spiders(node) when is_atom(node) do
    :rpc.call(node, Crawly.Engine, :running_spiders, [])
  end

  defp stop_spider(node, spider) when is_atom(spider) and is_atom(node) do
    :rpc.call(node, Crawly.Engine, :stop_spider, [spider])
  end
end

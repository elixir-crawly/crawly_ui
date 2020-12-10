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

  def create_spider(node, name) do
    node = String.to_atom(node)
    spider = CrawlyUI.Manager.get_spider!(name)

    name = spider.name

    links_to_follow =
      case spider.links_to_follow do
        nil ->
          []

        links_string ->
          String.split(links_string, "\r\n")
      end

    urls_from_rules = Map.keys(spider.rules)

    start_urls =
      spider.start_urls
      |> String.replace("\n", "")
      |> String.split("\r")

    start_urls = start_urls ++ urls_from_rules
    parsed_start_url = start_urls |> List.first() |> URI.parse()
    domain = "#{parsed_start_url.scheme}://#{parsed_start_url.host}"
    fields = spider.fields |> String.split(",")

    extractors =
      Map.values(spider.rules)
      |> Enum.map(fn rule ->
        rule
        |> Map.drop(["_document", "_url", "_page"])
      end)

    contents = """
    @impl Crawly.Spider
    def override_settings() do
      ui_node = System.get_env("UI_NODE") || "ui@127.0.0.1"
      ui_node = ui_node |> String.to_atom()

      pipelines = [
        {Crawly.Pipelines.Validate, fields: #{inspect(fields)}},
        {Crawly.Pipelines.Experimental.SendToUI, ui_node: ui_node}
      ]

      [pipelines: pipelines, closespider_itemcount: 10_000, concurrent_requests_per_domain: 10]
    end

    @impl Crawly.Spider
    def base_url(), do: "#{domain}"

    @impl Crawly.Spider
    def init(_opts) do
      [start_urls: #{inspect(start_urls)}]
    end

    @impl Crawly.Spider
    def parse_item(response) do
      {:ok, document} = Floki.parse_document(response.body)
      items = extract_items(document, response.request_url, #{inspect(extractors)})
      requests = extract_requests(document, base_url(), #{inspect(links_to_follow)})
      %{
          items: [items],
          requests: requests
      }
    end

    def extract_requests(document, base_url, filters) do
      hrefs =
        document
        |> Floki.find("a")
        |> Floki.attribute("href")
        |> Enum.filter(fn href ->
          case Enum.any?(filters, &String.contains?(href, &1)) do
            false -> false
            true -> true
          end
      end)
      absolute_urls = Enum.reduce(
        hrefs,
        [],
        fn url, acc ->
          parsed_merge = URI.merge(base_url, url)
          case parsed_merge.scheme in ["http", "https"] do
            true ->
              [parsed_merge |> to_string() | acc]
            false ->
              acc
          end
      end)
      # :io.format("[info] Following URLs was found on the page: ~p", [absolute_urls])
      Crawly.Utils.requests_from_urls(absolute_urls)
    end

    def extract_items(document, response_url, selectors_list) do
      selectors_list
      |> Enum.map(fn selectors ->
        extract(document, response_url, selectors)
      end)
      |> Enum.sort(&(Enum.count(&1) >= Enum.count(&2)))
      |> List.first()
    end

    def extract(document, response_url, selectors) do
      Enum.reduce(
        selectors,
        %{},
        fn
          {field, "response_url"}, acc ->
            Map.put(acc, field, response_url)

          {field, selector}, acc ->
            extracted_data =
              CrawlyUI.Utils.extract_data_with_complex_selector(document, selector)

            case extracted_data == "" do
              true -> acc
              false -> Map.put(acc, field, extracted_data)
            end
        end
        )
      end
    """

    IO.puts(contents)
    # Loading extraction utils
    {mod, bin, file} = :code.get_object_code(CrawlyUI.Utils)
    :rpc.call(node, :code, :load_binary, [mod, file, bin])

    # Loading generated module
    module = Module.concat(["#{name}"])
    contents = Code.string_to_quoted!(contents)
    {:module, name, code, _last} = Module.create(module, contents, Macro.Env.location(__ENV__))
    :rpc.call(node, :code, :load_binary, [name, 'some.filename', code])
  end
end

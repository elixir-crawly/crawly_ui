defmodule Spiders.OregonRegs do
  @moduledoc """
  Spider implementation for website state.or.us.
  """

  use Crawly.Spider

  @impl Crawly.Spider
  def override_settings() do
    ui_node = System.get_env("UI_NODE") || "ui@127.0.0.1"
    ui_node = ui_node |> String.to_atom()

    pipelines = [
      {Crawly.Pipelines.Validate, fields: [:url, :number, :chapter_number, :division_number]},
      {Crawly.Pipelines.DuplicatesFilter, item_id: :number},
      {Crawly.Pipelines.Experimental.SendToUI, ui_node: ui_node},
      Crawly.Pipelines.JSONEncoder,
      {Crawly.Pipelines.WriteToFile, extension: "json", folder: "/tmp"}
    ]

    [pipelines: pipelines, closespider_itemcount: 10_000]
  end

  @impl Crawly.Spider
  def base_url(), do: "https://secure.sos.state.or.us/oard/"

  @impl Crawly.Spider
  def init() do
    [
      start_urls: [
        "https://secure.sos.state.or.us/oard/ruleSearch.action"
      ]
    ]
  end

  @impl Crawly.Spider
  def parse_item(response) do
    {:ok, document} = Floki.parse_document(response.body)

    cond do
      String.contains?(response.request_url, ["?selectedChapter="]) ->
        parse_chapter_page(document)

      String.contains?(response.request_url, ["?selectedDivision="]) ->
        parse_division_page(document, response.request_url)

      true ->
        parse_search_page(document)
    end
  end

  defp parse_search_page(document) do
    [{_, _, chapters}] =
      document
      |> Floki.find("#selectedChapter")

    requests =
      chapters
      |> Enum.reject(fn {_, [{"value", db_id}], _} -> db_id == "-1" end)
      |> Enum.map(fn {_, [{"value", db_id}], _} ->
        "displayDivisionRules.action?selectedDivision=#{db_id}"
      end)
      |> Crawly.Utils.build_absolute_urls(base_url())
      |> Crawly.Utils.requests_from_urls()

    %Crawly.ParsedItem{:items => [], :requests => requests}
  end

  defp parse_chapter_page(document) do
    requests =
      document
      |> Floki.find("h3")
      |> Enum.take_every(2)
      |> Enum.map(fn division ->
        division
        |> Floki.attribute("a", "href")
        |> hd()
        |> String.replace(~r/action(.)*selected/, "action?selected")
      end)
      |> Crawly.Utils.build_absolute_urls(base_url())
      |> Crawly.Utils.requests_from_urls()

    %Crawly.ParsedItem{:items => [], :requests => requests}
  end

  defp parse_division_page(document, division_url) do
    document = document |> Floki.find("#content")

    chapter_division_info_map = parse_chapter_division_info(document, division_url)

    rules =
      document
      |> Floki.find(".rule_div")
      |> Enum.map(&parse_rule_item/1)
      |> Enum.map(&Map.merge(&1, chapter_division_info_map))

    %Crawly.ParsedItem{:items => rules, :requests => []}
  end

  defp parse_chapter_division_info(document, division_url) do
    chapter_name = document |> Floki.find("h1") |> Floki.text()

    [chapter_sub_name, chapter_number] =
      document
      |> Floki.find("h2")
      |> Floki.text()
      |> String.split(" - ")
      |> case do
        [chapter_number] -> ["", chapter_number]
        [chapter_sub_name, chapter_number] -> [chapter_sub_name, chapter_number]
      end

    chapter_url =
      document
      |> Floki.find("h2 a")
      |> Floki.attribute("href")
      |> hd()
      |> String.replace(~r/action(.)*selected/, "action?selected")
      |> Crawly.Utils.build_absolute_url(base_url())

    [division_number, division_name] =
      document |> Floki.find("h3") |> Floki.text() |> String.split("\n", parts: 2, trim: true)

    %{
      chapter_number: chapter_number,
      chapter_name: "#{chapter_name}, #{chapter_sub_name}",
      chapter_url: chapter_url,
      division_number: division_number,
      division_name: division_name,
      division_url: division_url
    }
  end

  defp parse_rule_item(rule) do
    [number, name] =
      rule
      |> Floki.find("p strong")
      |> Floki.text()
      |> String.replace(~r/\r|\n/, "")
      |> String.replace(~r/\d([A-Z])/, " \\1")
      |> String.split(" ", parts: 2)

    url = "view.action?ruleNumber=#{number}" |> Crawly.Utils.build_absolute_url(base_url())

    text = rule |> Floki.find("p p") |> Floki.text(sep: " ")

    meta = parse_meta_data(rule)

    %{
      number: number,
      name: name,
      url: url,
      content: text
    }
    |> Map.merge(meta)
  end

  defp parse_meta_data(rule) do
    {_, _, meta} = rule |> Floki.find("p") |> List.last()

    meta =
      meta
      |> Floki.text()

    parts = find_parts(meta)

    meta
    |> String.replace(~r/(\n\s)*/, "")
    |> String.split("\n", trim: true, parts: parts)
    |> Enum.reduce(%{}, fn data, acc_map ->
      [key, val] = String.split(data, ":")
      val = val |> String.trim() |> String.replace(~r/(\s(\s)+)|(\n)/, ", ")

      case key do
        "History" ->
          Map.put(acc_map, :history, val)

        "Statutory/Other Authority" ->
          Map.put(acc_map, :authority, val)

        "Statutes/Other Implemented" ->
          Map.put(acc_map, :implements, val)

        _ ->
          acc_map
      end
    end)
  end

  defp find_parts(text) do
    cond do
      String.contains?(text, "Statutory/Other Authority") and
          String.contains?(text, "Statutes/Other Implemented") ->
        3

      not String.contains?(text, "Statutory/Other Authority") and
          not String.contains?(text, "Statutes/Other Implemented") ->
        1

      true ->
        2
    end
  end
end

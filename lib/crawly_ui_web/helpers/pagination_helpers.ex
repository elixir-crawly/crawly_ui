defmodule CrawlyUIWeb.PaginationHelpers do
  @page_size 10

  def render_pages(page, page_number) do
    case page_number do
      page_number when page_number == page ->
        "<strong> #{page_number} </strong>"

      ".." ->
        ".."

      _ ->
        "<a phx-click=\"goto_page\" phx-value-page=#{page_number}> #{page_number} </a>"
    end
  end

  def render_goto_next(page, data) do
    number_of_pages = number_of_pages(data)

    if page != number_of_pages do
      "<a phx-click=\"goto_page\" phx-value-page=#{page + 1}> >> </a>"
    end
  end

  def render_goto_prev(page) do
    if page > 1 do
      "<a phx-click=\"goto_page\" phx-value-page=#{page - 1}> << </a>"
    end
  end

  def list_pages(page, data) do
    number_of_pages = number_of_pages(data)

    cond do
      number_of_pages == 0 ->
        []

      number_of_pages <= 10 ->
        Enum.to_list(1..number_of_pages)

      page >= 1 and page < 6 ->
        Enum.concat([1..6, [number_of_pages]])

      page <= number_of_pages and page > number_of_pages - 5 ->
        start_index = number_of_pages - 5
        Enum.concat([1], start_index..number_of_pages)

      true ->
        start_index = page - 4
        end_index = page + 4

        Enum.concat([1, number_of_pages], start_index..end_index)
        |> Enum.uniq()
        |> Enum.sort()
    end
    |> may_put_separator()
  end

  def paginate(data, page_number) do
    page_size = page_size()
    Enum.slice(data, (page_number - 1) * page_size, page_size)
  end

  defp number_of_pages(data) do
    (length(data) / page_size()) |> ceil()
  end

  defp page_size do
    Application.get_env(:crawly_ui, :page_size, @page_size)
  end

  defp may_put_separator(page_list) do
    may_put_separator(page_list, []) |> Enum.reverse()
  end

  defp may_put_separator([], res), do: res
  defp may_put_separator([last], res), do: [last | res]

  defp may_put_separator([h, next | t], res) do
    if h + 1 == next do
      may_put_separator([next | t], [h | res])
    else
      may_put_separator([next | t], ["..", h | res])
    end
  end
end

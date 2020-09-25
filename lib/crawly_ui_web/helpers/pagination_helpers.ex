defmodule CrawlyUIWeb.PaginationHelpers do
  @doc """
  Render html for pagination, list all available pages and link to the pages
  """
  def render_pages(page, page_number) do
    case page_number do
      page_number when page_number == page ->
        "<strong> #{page_number} </strong>"

      ".." ->
        ".."

      _ ->
        "<a href=\"#\" phx-click=\"goto_page\" phx-value-page=#{page_number}> #{page_number} </a>"
    end
  end

  @doc """
  Render html for go to next page when there are more than 1 page
  """
  def render_goto_next(page, number_of_pages) do
    if page != number_of_pages and number_of_pages > 1 do
      "<a href=\"#\" phx-click=\"goto_page\" phx-value-page=#{page + 1}> >> </a>"
    end
  end

  @doc """
  Render html for go to previous page when there are more than 1 page
  """
  def render_goto_prev(page, number_of_pages) do
    if page > 1 and number_of_pages > 1 do
      "<a href=\"#\" phx-click=\"goto_page\" phx-value-page=#{page - 1}> << </a>"
    end
  end

  @doc """
  List the number amount of pages for given data, truncate when the list is too long
  """
  def list_pages(page, number_of_pages) do
    cond do
      # No pagination if there is 1 or less page
      number_of_pages <= 1 ->
        []

      # List all pages if there are less than 10 pages
      number_of_pages <= 10 ->
        Enum.to_list(1..number_of_pages)

      # List and truncate the pages if there are more than 10 pages
      page >= 1 and page < 5 ->
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

  defp may_put_separator(page_list) do
    # put ".." between page numbers if they are not continuous, i.e. [1, "..", 7, 8, 9, "..", 14]
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

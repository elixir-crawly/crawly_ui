defmodule CrawlyUIWeb.PaginationHelpers do
  @moduledoc """
  Uses for pages pagination.
  """

  def simple_pagination(page, total_pages, link_params \\ nil) do
    min =
      case page - 5 <= 0 do
        true -> 0
        false -> page - 5
      end

    max =
      case page + 5 >= total_pages do
        true -> total_pages
        false -> page + 5
      end

    pages =
      Enum.map(
        min..max,
        fn
          ^page ->
            "<li class='active'><a href='#{build_pagination_url(page, link_params)}'>#{page}</a></li>"

          x ->
            "<li><a href='#{build_pagination_url(x, link_params)}'>#{x}</a></li>"
        end
      )

    """
    <nav>
    <ul class="pagination">
    #{pages}
    </ul>
    </nav>
    """
  end

  defp build_pagination_url(page, nil), do: "?page=#{page}"
  defp build_pagination_url(page, extra_params), do: "?page=#{page}&#{extra_params}"

  def pagination_links(page, total_pages) do
    goto_next = render_goto_next(page, total_pages)
    goto_prev = render_goto_prev(page, total_pages)

    pages =
      for page_number <- list_pages(page, total_pages) do
        render_pages(page, page_number)
      end

    """
    <nav>
    <ul class="pagination">
    #{goto_prev}
    #{pages}
    #{goto_next}
    </ul>
    </nav>
    """
  end

  defp render_pages(page, page_number) do
    case page_number do
      page_number when page_number == page ->
        "<li class=\"active\"><a href=\"#\">#{page}</a></li>"

      ".." ->
        "<li>..</li>"

      _ ->
        "<li><a href=\"#\" phx-click=\"goto_page\" phx-value-page=#{page_number}>#{page_number}</a></li>"
    end
  end

  defp render_goto_next(page, number_of_pages) do
    if page != number_of_pages and number_of_pages > 1 do
      "<a href=\"#\" phx-click=\"goto_page\" phx-value-page=#{page + 1}> >> </a>"
    end
  end

  defp render_goto_prev(page, number_of_pages) do
    if page > 1 and number_of_pages > 1 do
      "<a href=\"#\" phx-click=\"goto_page\" phx-value-page=#{page - 1}> << </a>"
    end
  end

  defp list_pages(page, number_of_pages) do
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

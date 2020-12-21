defmodule CrawlyUI.Queries.Log do
  @moduledoc """
  Contains queries related to Log schema
  """

  alias CrawlyUI.Manager.Log

  import Ecto.Query, warn: false
  alias CrawlyUI.Repo

  def create_log(attrs \\ %{}) do
    category = log_mod_2_category(Map.get(attrs, :mod))
    attrs = Map.put(attrs, :category, category)

    %Log{}
    |> Log.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  List generated spiders
  """
  def list_logs(job_id, %{page: p, limit: l}, filter) do
    Log
    |> where([l], l.job_id == ^job_id)
    |> maybe_apply_category_filters(filter)
    |> order_by(desc: :inserted_at)
    |> limit(^l)
    |> offset(^p)
    |> Repo.all()
  end

  defp maybe_apply_category_filters(query, "all"), do: query

  defp maybe_apply_category_filters(query, filter) do
    query |> where([l], l.category == ^filter)
  end

  def count_logs(job_id, filter) do
    maybe_extra_filter =
      case filter do
        "all" -> ""
        f -> "AND category = ''#{f}''"
      end

    result =
      Repo.query!("""
        SELECT
          count_estimate(
            'SELECT * FROM logs
              WHERE job_id = #{job_id} #{maybe_extra_filter}')
      """)

    [[rows]] = result.rows
    rows
  end

  defp log_mod_2_category(mod) do
    mod = String.downcase(mod)

    cond do
      String.contains?(mod, "worker") -> :worker
      String.contains?(mod, "manager") -> :manager
      String.contains?(mod, "pipeline") -> :items
      String.contains?(mod, "middleware") -> :requests
      true -> :other
    end
  end
end

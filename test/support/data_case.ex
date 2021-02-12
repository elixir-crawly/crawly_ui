defmodule CrawlyUI.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use CrawlyUI.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias CrawlyUI.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import CrawlyUI.Manager
      import CrawlyUI.DataCase
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(CrawlyUI.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(CrawlyUI.Repo, {:shared, self()})
    end

    :ok
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  def insert_job(params \\ %{}) do
    params =
      Map.merge(%{spider: "Crawly", state: "running", tag: "test", node: "crawly@test"}, params)

    CrawlyUI.Repo.insert!(struct(CrawlyUI.Manager.Job, params))
  end

  def insert_item(job_id, inserted_at \\ nil, data \\ %{}) do
    inserted_at =
      case inserted_at do
        nil -> inserted_at_valid()
        _ -> inserted_at
      end

    CrawlyUI.Repo.insert!(%CrawlyUI.Manager.Item{
      job_id: job_id,
      inserted_at: inserted_at,
      data: data
    })
  end

  def insert_log(job_id) do
    CrawlyUI.Repo.insert!(%CrawlyUI.Manager.Log{
      job_id: job_id,
      mod: "undefined",
      message: "Dropping request: \"\" (domain filter)"
    })
  end

  def inserted_at_valid(), do: inserted_at(0)

  @job_abandoned_timeout 60 * 30 + 10
  def inserted_at_expired, do: inserted_at(@job_abandoned_timeout)

  def inserted_at(shift) do
    NaiveDateTime.utc_now()
    |> NaiveDateTime.add(shift * -1, :second)
    |> NaiveDateTime.truncate(:second)
  end
end

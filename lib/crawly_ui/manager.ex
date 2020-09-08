defmodule CrawlyUI.Manager do
  @moduledoc """
  The Manager context.
  """

  import Ecto.Query, warn: false
  alias CrawlyUI.Repo

  alias CrawlyUI.Manager.Job
  alias CrawlyUI.Manager.Item

  @job_abandoned_timeout 60 * 30

  def update_job_status() do
    running_jobs = from(j in Job, where: j.state == ^"running") |> Repo.all()

    Enum.each(running_jobs, fn job ->
      case is_job_abandoned(job) do
        true ->
          update_job(job, %{state: "abandoned"})

        false ->
          :ok
      end
    end)
  end

  def is_job_abandoned(job) do
    case most_recent_item(job.id) do
      nil ->
        NaiveDateTime.diff(NaiveDateTime.utc_now(), job.inserted_at, :second) >
          @job_abandoned_timeout

      item ->
        NaiveDateTime.diff(NaiveDateTime.utc_now(), item.inserted_at, :second) >
          @job_abandoned_timeout
    end
  end

  @doc """
  Returns the list of jobs

  ## Examples

      iex> list_jobs()
      [%Job{}, ...]}

  """
  def list_jobs() do
    from(j in Job, order_by: [desc: :state, desc: :inserted_at]) |> Repo.all()
  end

  @doc """
  Gets a single job.

  Raises `Ecto.NoResultsError` if the Job does not exist.

  ## Examples

      iex> get_job!(123)
      %Job{}

      iex> get_job!(456)
      ** (Ecto.NoResultsError)

  """
  def get_job!(id), do: Repo.get!(Job, id)

  @doc """
  Creates a job.

  ## Examples

      iex> create_job(%{field: value})
      {:ok, %Job{}}

      iex> create_job(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_job(attrs \\ %{}) do
    %Job{}
    |> Job.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a job.

  ## Examples

      iex> update_job(job, %{field: new_value})
      {:ok, %Job{}}

      iex> update_job(job, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_job(%Job{} = job, attrs) do
    job
    |> Job.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a job.

  ## Examples

      iex> delete_job(job)
      {:ok, %Job{}}

      iex> delete_job(job)
      {:error, %Ecto.Changeset{}}

  """
  def delete_job(%Job{} = job) do
    Repo.delete(job)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking job changes.

  ## Examples

      iex> change_job(job)
      %Ecto.Changeset{source: %Job{}}

  """
  def change_job(%Job{} = job) do
    Job.changeset(job, %{})
  end

  def job_state(job) do
    %{state: state} = Repo.get(Job, job.id)
    state
  end

  @doc """
  Returns run time of the given job

  ## Examples

      iex> run_time(job)
      5

  """
  def run_time(%Job{inserted_at: start} = job) do
    case most_recent_item(job.id) do
      nil ->
        0.0

      item ->
        NaiveDateTime.diff(item.inserted_at, start, :second) / 60
    end
  end

  def crawl_speed(job) do
    start_time = Timex.now()
    end_time = Timex.shift(start_time, minutes: -1)

    Repo.one(
      from i in "items",
        where: i.job_id == ^job.id and i.inserted_at > ^end_time and i.inserted_at < ^start_time,
        select: count("*")
    )
  end

  @doc """
  Returns number of items for given job

  ## Examples

      iex> count_items(job)
      100

  """
  def count_items(job) do
    Repo.one(from i in "items", where: i.job_id == ^job.id, select: count("*"))
  end

  @doc """
  Update item counts for all running jobs
  """
  def update_item_counts(jobs) do
    Enum.each(jobs, fn job ->
      cnt = count_items(job)
      {:ok, _} = update_job(job, %{items_count: cnt})
    end)
  end

  @doc """
  Update crawl speed for all active jobs
  """
  def update_crawl_speeds(jobs) do
    start_time = Timex.now()
    end_time = Timex.shift(start_time, minutes: -1)

    Enum.each(jobs, fn job ->
      cnt =
        Repo.one(
          from i in "items",
            where:
              i.job_id == ^job.id and i.inserted_at > ^end_time and i.inserted_at < ^start_time,
            select: count("*")
        )

      {:ok, _} = update_job(job, %{crawl_speed: cnt})
    end)
  end

  @doc """
  Update run times for all active jobs
  """
  def update_run_times(jobs) do
    Enum.each(jobs, fn job ->
      cnt = run_time(job) |> trunc()
      {:ok, _} = update_job(job, %{run_time: cnt})
    end)
  end

  def update_running_jobs() do
    jobs = from(j in Job, where: j.state == ^"running") |> Repo.all()
    update_run_times(jobs)
    update_crawl_speeds(jobs)
    update_item_counts(jobs)
  end

  def update_all_jobs() do
    jobs = from(j in Job) |> Repo.all()
    update_run_times(jobs)
    update_crawl_speeds(jobs)
    update_item_counts(jobs)
  end

  def get_job_by_tag(tag) do
    Repo.one(from j in Job, where: j.tag == ^tag)
  end

  @doc """
  Returns the list of items for a specific job that match the search string (if provided).

  ## Examples

      iex> list_items(1, %{"search" => "id:1"})
      [%Item{}, ...]

  """
  def list_items(job_id, params) do
    query =
      case Map.get(params, "search") do
        nil ->
          Item
          |> where([i], i.job_id == ^job_id)

        search ->
          case String.contains?(search, ":") do
            true ->
              [key, value] = String.split(search, ":")
              value = "%#{String.trim(value)}%"

              Item
              |> where([i], i.job_id == ^job_id)
              |> where([i], fragment("data->>? ILIKE ?", ^key, ^value))

            false ->
              Item
              |> where([i], i.job_id == ^job_id)
          end
      end

    query |> order_by(desc: :inserted_at) |> Repo.all()
  end

  @doc """
  Gets a single item.

  Raises `Ecto.NoResultsError` if the Item does not exist.

  ## Examples

      iex> get_item!(123)
      %Item{}

      iex> get_item!(456)
      ** (Ecto.NoResultsError)

  """
  def get_item!(id), do: Repo.get!(Item, id)

  def most_recent_item(job_id) do
    from(i in Item, where: i.job_id == ^job_id, order_by: [desc: :inserted_at], limit: 1)
    |> Repo.one()
  end

  def next_item(item) do
    from(i in Item, where: i.job_id == ^item.job_id, order_by: fragment("RANDOM()"), limit: 1)
    |> Repo.one()
  end

  @doc """
  Creates a item.

  ## Examples

      iex> create_item(%{field: value})
      {:ok, %Item{}}

      iex> create_item(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_item(attrs \\ %{}) do
    %Item{}
    |> Item.changeset(attrs)
    |> Repo.insert(returning: false)
  end

  @doc """
  Updates a item.

  ## Examples

      iex> update_item(item, %{field: new_value})
      {:ok, %Item{}}

      iex> update_item(item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_item(%Item{} = item, attrs) do
    item
    |> Item.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a item.

  ## Examples

      iex> delete_item(item)
      {:ok, %Item{}}

      iex> delete_item(item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_item(%Item{} = item) do
    Repo.delete(item)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking item changes.

  ## Examples

      iex> change_item(item)
      %Ecto.Changeset{source: %Item{}}

  """
  def change_item(%Item{} = item) do
    Item.changeset(item, %{})
  end
end

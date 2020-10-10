defmodule CrawlyUI.Manager do
  @moduledoc """
  The Manager context.
  """

  import Ecto.Query, warn: false
  alias CrawlyUI.Repo

  alias CrawlyUI.Manager.Job
  alias CrawlyUI.Manager.Item
  alias CrawlyUI.Manager.Spider

  alias CrawlyUI.SpiderManager

  require Logger

  @job_abandoned_timeout 60 * 30

  @doc """
  Update all job status if the jobs are determined abandonned.

  If the job is abandonned, try to reach the worker node to close the spider.
  If success and spider is running, job state is put to "abandonned" and tell the worker to close the spider. If node is reachable but spider with the same tag is not running, then job stat is put to "stopped". Otherwise, update job state to "node down"

  """
  def update_job_status() do
    running_jobs = list_running_jobs()

    Enum.each(running_jobs, fn job ->
      case is_job_abandoned(job) do
        true ->
          state =
            case SpiderManager.close_job_spider(job) do
              {:ok, :stopped} -> "abandoned"
              {:error, :nodedown} -> "node down"
              _ -> "stopped"
            end

          update_job(job, %{state: state})

        false ->
          :ok
      end
    end)
  end

  @doc """
  Returns true if the most recent item of the job was inserted before set time out. Otherwise false.

  ## Examples

      iex> is_job_abandoned(job)
      true

  """
  def is_job_abandoned(%Job{} = job) do
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
  Returns the list of jobs with provided query, else returns all jobs

  ## Examples

      iex> list_jobs()
      [%Job{}, ...]}

      iex> list_jobs(from(j in Job,  where: j.state == "running"))
      [%Job{}, ...]}

  """
  def list_jobs(query \\ Job, params) do
    query
    |> order_by(desc: :state, desc: :inserted_at)
    |> Repo.paginate(params)
  end

  @doc """
  List only running jobs
  """
  def list_running_jobs(params \\ []) do
    Job
    |> where([j], j.state == "running")
    |> list_jobs(params)
  end

  @doc """
  List recent jobs that are not running
  """
  def list_recent_jobs() do
    Job
    |> where([j], not (j.state == "running"))
    |> order_by(desc: :inserted_at)
    |> Repo.paginate(page: 1, page_size: 5)
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
  Deletes all items belong to a specific job
  """
  def delete_all_job_items(job) do
    items = list_items(job.id)

    Enum.map(items, &delete_item/1)
  end

  @doc """
  Make rpc call through Spider Manager to close spider. Depending on the reply, update the Job state accordingly.

  ## Examples

      iex> cancel_running_job(job)
      {:ok, %Job{state: "cancelled"}}

  """
  def cancel_running_job(job) do
    state =
      case SpiderManager.close_job_spider(job) do
        {:ok, :stopped} ->
          "cancelled"

        {:error, :nodedown} ->
          "node down"

        _ ->
          "stopped"
      end

    crawl_speed = crawl_speed(job)
    update_job(job, %{state: state, crawl_speed: crawl_speed})
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

  @doc """
  Returns crawl speed time of the given job. Returns average crawl speed if the job is not running

  ## Examples

      iex> crawl_speed(job)
      3

  """
  def crawl_speed(%{state: "running"} = job) do
    start_time = Timex.now()
    end_time = Timex.shift(start_time, minutes: -1)

    Repo.one(
      from(i in "items",
        where: i.job_id == ^job.id and i.inserted_at > ^end_time and i.inserted_at < ^start_time,
        select: count("*")
      )
    )
  end

  def crawl_speed(job) do
    if job.run_time == 0 do
      job.items_count
    else
      (job.items_count / job.run_time) |> round
    end
  end

  @doc """
  Returns number of items for given job

  ## Examples

      iex> count_items(job)
      100

  """
  def count_items(job) do
    Repo.one(from(i in "items", where: i.job_id == ^job.id, select: count("*")))
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
    Enum.each(jobs, fn job ->
      cnt = crawl_speed(job)
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

  @doc """
  Update crawl speed, run time and item counts for all active jobs
  """
  def update_running_jobs() do
    jobs = list_running_jobs()
    update_run_times(jobs)
    update_crawl_speeds(jobs)
    update_item_counts(jobs)
  end

  @doc """
  Update crawl speed, run time and item counts for all active jobs
  """
  def update_jobs_speed() do
    Logger.info("Updating crawl speeds")

    jobs =
      Job
      |> where([j], j.crawl_speed == 0 and j.state != "running")
      |> Repo.all()

    Enum.each(
      jobs,
      fn job ->
        if job.run_time != 0 do
          update_job(job, %{crawl_speed: (job.items_count / job.run_time) |> trunc()})
        end
      end
    )
  end

  @doc """
  Update crawl speed, run time and item counts for all jobs
  """
  def update_all_jobs() do
    jobs = from(j in Job) |> Repo.all()
    update_run_times(jobs)
    update_item_counts(jobs)

    # Crawl speed for all jobs need updated runtime and items count
    from(j in Job) |> Repo.all() |> update_crawl_speeds()
  end

  def get_job_by_tag(tag) do
    Repo.one(from(j in Job, where: j.tag == ^tag))
  end

  @doc """
  Returns the list of items for a specific job that match the search string (if provided).

  ## Examples

      iex> list_items(1, %{"search" => "id:1"})
      [%Item{}, ...]

  """
  def list_items(job_id), do: list_items(job_id, [])

  def list_items(job_id, params) do
    query = Item |> where([i], i.job_id == ^job_id)

    query =
      case Keyword.get(params, :search) do
        nil ->
          query

        search_string ->
          case search(search_string) do
            {:error, :parse_error} ->
              query

            ecto_fragment ->
              query
              |> where([i], ^ecto_fragment)
          end
      end

    query
    |> order_by(desc: :inserted_at)
    |> Repo.paginate(params)
  end

  def parse_search_string(search_string) do
    case CrawlyUI.QueryParser.query(search_string) do
      {:ok, [], _rest, _map, _, _} -> {:error, :parse_error}
      {:ok, tokens, _rest, _map, _, _} -> {:ok, tokens}
    end
  end

  # Return an ECTO fragement for the given search query
  def search(search_string) do
    with {:ok, tokens} <- parse_search_string(search_string),
         tokens = Enum.map(tokens, &String.trim(&1)) do
      # take first two elements from the list
      [key, value | rest] = tokens

      Enum.reduce(
        Enum.chunk_every(rest, 3),
        dynamic(fragment("data->>? ILIKE ?", ^key, ^value)),
        fn
          ["||", key, value], acc ->
            dynamic(^acc or fragment("data->>? ILIKE ?", ^key, ^value))

          ["&&", key, value], acc ->
            dynamic(^acc and fragment("data->>? ILIKE ?", ^key, ^value))
        end
      )
    end
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

  def create_spider(attrs \\ %{}) do
    attrs = Map.update!(attrs, "rules", fn v -> encode_rules(v) end)

    %Spider{}
    |> Spider.changeset(attrs)
    |> Repo.insert(returning: false)
  end

  def update_spider(name, attrs) do
    attrs = Map.update!(attrs, "rules", fn v -> encode_rules(v) end)
    case CrawlyUI.Manager.get_spider!(name) do
      nil ->
        {:error, :not_found}
      data ->
        CrawlyUI.Manager.Spider.changeset(data, attrs) |> Repo.update()
    end
  end

  @doc """
  List generated spiders
  """
  def list_spiders(query \\ Spider, params) do
    query
    |> order_by(desc: :inserted_at)
    |> Repo.paginate(params)
  end

  def get_spider!(name) do
    case Repo.get_by(Spider, [name: name]) do
      nil ->
        nil
      data ->
        Map.update!(data, :rules, fn v -> decode_rules(v) end)
    end
  end

  # Convert all values in rules into Base encoded binaries (so they can be stored
  # in database)
  defp encode_rules(rules) do
    Enum.into(
      rules,
      %{},
      fn {k, v} -> {k, v |> :erlang.term_to_binary() |> Base.encode16()} end
    )
  end

  # Convert all values in rules into Base encoded binaries (so they can be stored
  # in database)
  defp decode_rules(rules) do
    Enum.into(
      rules,
      %{},
      fn {k, v} -> {k, v |> Base.decode16!() |> :erlang.binary_to_term()} end
    )
  end


end

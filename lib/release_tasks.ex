defmodule CrawlyUI.ReleaseTasks do
  alias Ecto.Migrator

  @otp_app :crawly_ui
  @start_apps [:crawly_ui, :logger, :ssl, :postgrex, :ecto]

  def migrate do
    init(@otp_app, @start_apps)

    run_migrations_for(@otp_app)

    stop()
  end

  def seed do
    init(@otp_app, @start_apps)

    "#{seed_path(@otp_app)}/*.exs"
    |> Path.wildcard()
    |> Enum.sort()
    |> Enum.each(&run_seed_script/1)

    stop()
  end

  defp init(app, start_apps) do
    IO.puts "Loading app.."
    :ok = Application.load(app)

    IO.puts "Starting dependencies.."
    Enum.each(start_apps, &Application.ensure_all_started/1)

    IO.puts "Starting repos.."
    app
    |> Application.get_env(:ecto_repos, [])
    |> Enum.each(&(&1.start_link(pool_size: 1)))
  end

  defp stop do
    IO.puts "Success!"
    :init.stop()
  end

  defp run_migrations_for(app) do
    IO.puts "Running migrations for #{app}"

    app
    |> Application.get_env(:ecto_repos, [])
    |> Enum.each(&Migrator.run(&1, migrations_path(app), :up, all: true))
  end

  defp run_seed_script(seed_script) do
    IO.puts "Running seed script #{seed_script}.."
    Code.eval_file(seed_script)
  end

  defp migrations_path(app),
       do: priv_dir(app, ["repo", "migrations"])

  defp seed_path(app),
       do: priv_dir(app, ["repo", "seeds"])

  defp priv_dir(app, path) when is_list(path) do
    case :code.priv_dir(app) do
      priv_path when is_list(priv_path) or is_binary(priv_path) ->
        Path.join([priv_path] ++ path)

      {:error, :bad_name} ->
        raise ArgumentError, "unknown application: #{inspect app}"
    end
  end
end
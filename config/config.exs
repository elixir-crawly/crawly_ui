# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :crawly_ui,
  ecto_repos: [CrawlyUI.Repo]

config :crawly_ui, CrawlyUIWeb.JobLive, update_interval: 20_000

# Configures the endpoint
config :crawly_ui, CrawlyUIWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "NvJbkg8LD2bwbr4pT6v7UoaiqcaHIwIkCath+ECqQGN36U9CnCD5o3K8geVuKAmF",
  render_errors: [view: CrawlyUIWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: CrawlyUI.PubSub,
  live_view: [signing_salt: "mKlOeOvv3fK8OTEEYjXqPaFqBXoVvRcC"]

config :logger,
  backends: [:console, {LoggerFileBackend, :debug_log}]

# configuration for the {LoggerFileBackend, :error_log} backend
config :logger, :debug_log,
  path: System.get_env("LOG_PATH", "/tmp/ui_debug.log"),
  level: :debug

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :crawly_ui, CrawlyUI.Scheduler,
  jobs: [
    # Every 5 mins
    {"*/5 * * * *", {CrawlyUI.Manager, :update_job_status, []}},

    # Every 5 mins
    {"*/5 * * * *", {CrawlyUI.Manager, :update_running_jobs, []}},

    # Every 5 mins
    {"*/5 * * * *", {CrawlyUI.Manager, :update_jobs_speed, []}}
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

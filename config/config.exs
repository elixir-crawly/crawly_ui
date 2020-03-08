# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :crawly_ui,
  ecto_repos: [CrawlyUI.Repo]

# Configures the endpoint
config :crawly_ui, CrawlyUIWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "NvJbkg8LD2bwbr4pT6v7UoaiqcaHIwIkCath+ECqQGN36U9CnCD5o3K8geVuKAmF",
  render_errors: [view: CrawlyUIWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: CrawlyUI.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [signing_salt: "FEQCdMDy"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configuration for scrivener_html
config :scrivener_html,
       routes_helper: CrawlyUIWeb.Router.Helpers,
       view_style: :bootstrap

config :crawly_ui, CrawlyUI.Scheduler,
       jobs: [
         # Every 5 minutes
         {"*/5 * * * *",      {CrawlyUI.Manager, :update_job_status, []}},
       ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

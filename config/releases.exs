# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
import Config

database_url =
  System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

config :crawly_ui, CrawlyUI.Repo,
  # ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

secret_key_base =
  System.get_env("SECRET_KEY_BASE") ||
    raise """
    environment variable SECRET_KEY_BASE is missing.
    You can generate one by calling: mix phx.gen.secret
    """

config :crawly_ui, CrawlyUIWeb.Endpoint,
  url: [host: System.get_env("HOSTNAME") || "localhost"],
  http: [
    port: String.to_integer(System.get_env("PORT") || "4000"),
    transport_options: [socket_opts: [:inet6]]
  ],
  secret_key_base: secret_key_base

config :crawly_ui, CrawlyUIWeb.JobLive, update_interval: 20_000
config :crawly_ui, CrawlyUIWeb.ItemLive, update_interval: 20_000

config :logger,
  backends: [:console, {LoggerFileBackend, :debug_log}]

# configuration for the {LoggerFileBackend, :error_log} backend
config :logger, :debug_log,
  path: System.get_env("LOG_PATH", "/tmp/debug.log"),
  level: :debug

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :crawly_ui, CrawlyUIWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.

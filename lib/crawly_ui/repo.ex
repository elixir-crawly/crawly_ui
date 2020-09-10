defmodule CrawlyUI.Repo do
  use Ecto.Repo,
    otp_app: :crawly_ui,
    adapter: Ecto.Adapters.Postgres
end

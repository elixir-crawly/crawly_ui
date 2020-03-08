defmodule CrawlyUI.Repo do
  use Ecto.Repo,
    otp_app: :crawly_ui,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 10
end

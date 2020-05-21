defmodule CrawlyUI.Repo.Migrations.AddItemCountCrawlSpeed do
  use Ecto.Migration

  def change do
    alter table(:jobs) do
      add :items_count, :integer
      add :crawl_speed, :integer
      add :run_time, :integer
    end
  end
end

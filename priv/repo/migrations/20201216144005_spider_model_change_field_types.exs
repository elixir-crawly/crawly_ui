defmodule CrawlyUI.Repo.Migrations.SpiderModelChangeFieldTypes do
  use Ecto.Migration

  def change do
    alter table(:spiders) do
      modify :start_urls, :text
      modify :links_to_follow, :text
    end
  end
end

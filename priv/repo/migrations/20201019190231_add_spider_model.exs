defmodule CrawlyUI.Repo.Migrations.AddSpiderModel do
  use Ecto.Migration

  def change do
    create table(:spiders) do
      add :name, :string
      add :start_urls, :string
      add :fields, :string
      add :links_to_follow, :string
      add :rules, :map

      timestamps()
    end

    create unique_index(:spiders, [:name])
  end
end

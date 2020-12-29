defmodule CrawlyUI.Repo.Migrations.LogTableAddCategoryIndex do
  use Ecto.Migration

  def change do
    create index(:logs, [:category])
  end
end

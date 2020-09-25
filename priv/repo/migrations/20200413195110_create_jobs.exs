defmodule CrawlyUI.Repo.Migrations.CreateJobs do
  use Ecto.Migration

  def change do
    create table(:jobs) do
      add :spider, :string
      add :state, :string
      add :tag, :string
      add :node, :string

      timestamps()
    end
  end
end

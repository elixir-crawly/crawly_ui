defmodule CrawlyUI.Repo.Migrations.CreateItems do
  use Ecto.Migration

  def change do
    create table(:items) do
      add :data, :map
      add :job_id, references(:jobs, on_delete: :nothing)

      timestamps()
    end

    create index(:items, [:job_id])
  end
end

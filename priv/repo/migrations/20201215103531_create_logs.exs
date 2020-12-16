defmodule CrawlyUi.Repo.Migrations.CreateLogs do
  use Ecto.Migration

  def change do
    create table(:logs) do
      add :job_id, references(:jobs, on_delete: :nothing)
      add :message, :text

      timestamps()
    end

    create index(:logs, [:job_id])
  end
end

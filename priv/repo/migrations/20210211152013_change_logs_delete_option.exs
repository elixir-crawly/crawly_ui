defmodule CrawlyUI.Repo.Migrations.ChangeLogsDeleteOption do
  use Ecto.Migration

  def change do
    alter table(:logs) do
      modify :job_id, references(:jobs, on_delete: :nothing),
        from: references(:jobs, on_delete: :delete_all)
    end
  end
end

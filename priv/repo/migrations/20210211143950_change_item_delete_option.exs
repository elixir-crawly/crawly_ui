defmodule CrawlyUI.Repo.Migrations.ChangeItemsDeleteOption do
  use Ecto.Migration

  def change do
    alter table(:items) do
      modify :job_id, references(:jobs, on_delete: :nothing),
        from: references(:jobs, on_delete: :delete_all)
    end
  end
end

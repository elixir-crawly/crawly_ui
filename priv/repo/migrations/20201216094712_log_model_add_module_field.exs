defmodule CrawlyUI.Repo.Migrations.LogModelAddModuleField do
  use Ecto.Migration

  def change do
    alter table(:logs) do
      add :mod, :string
    end
  end
end

defmodule CrawlyUI.Repo.Migrations.LogTableAddInsertedAtIndex do
  use Ecto.Migration

  def change do
    alter table(:logs) do
      add :category, :string
    end

    create index(:logs, [:inserted_at])

    # Create a function for fast counts
    execute(
      """
      CREATE FUNCTION count_estimate(query text) RETURNS integer AS $$
      DECLARE
      rec   record;
      rows  integer;
      BEGIN
      FOR rec IN EXECUTE 'EXPLAIN ' || query LOOP
        rows := substring(rec."QUERY PLAN" FROM ' rows=([[:digit:]]+)');
      EXIT WHEN rows IS NOT NULL;
      END LOOP;
      RETURN rows;
      END;
      $$ LANGUAGE plpgsql VOLATILE STRICT;
      """,
      "DROP FUNCTION count_estimate"
    )
  end
end

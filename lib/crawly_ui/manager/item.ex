defmodule CrawlyUI.Manager.Item do
  @moduledoc """
  Schema for items table.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "items" do
    field :data, :map
    belongs_to :job, CrawlyUI.Manager.Job

    timestamps()
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:data, :job_id])
    |> validate_required([:data, :job_id])
  end
end

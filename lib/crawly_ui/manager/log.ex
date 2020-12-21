defmodule CrawlyUI.Manager.Log do
  use Ecto.Schema
  import Ecto.Changeset

  schema "logs" do
    field :message, :string
    field :job_id, :id
    field :mod, :string
    field :category, Ecto.Enum, values: [:manager, :worker, :requests, :items, :other]

    timestamps()
  end

  @doc false
  def changeset(log, attrs) do
    log
    |> cast(attrs, [:job_id, :message, :mod, :category])
    |> validate_required([:job_id, :message, :mod])
  end
end

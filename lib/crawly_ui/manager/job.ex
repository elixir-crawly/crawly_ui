defmodule CrawlyUI.Manager.Job do
  use Ecto.Schema
  import Ecto.Changeset

  schema "jobs" do
    field :spider, :string
    field :state, :string
    field :tag, :string
    field :node, :string

    timestamps()
  end

  @doc false
  def changeset(job, attrs) do
    job
    |> cast(attrs, [:spider, :state, :tag, :node])
    |> validate_required([:spider, :state, :tag, :node])
  end
end

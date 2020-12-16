defmodule CrawlyUI.Manager.Log do
  use Ecto.Schema
  import Ecto.Changeset

  schema "logs" do
    field :message, :string
    field :job_id, :id

    timestamps()
  end

  @doc false
  def changeset(log, attrs) do
    log
    |> cast(attrs, [:job_id, :message])
    |> validate_required([:job_id, :message])
  end
end

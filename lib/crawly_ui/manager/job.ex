defmodule CrawlyUI.Manager.Job do
  use Ecto.Schema
  import Ecto.Changeset

  schema "jobs" do
    field :spider, :string
    field :state, :string
    field :tag, :string
    field :node, :string
    field :items_count, :integer, default: 0
    field :crawl_speed, :integer, default: 0
    field :run_time, :integer, default: 0
    timestamps()
  end

  @doc false
  def changeset(job, attrs) do
    job
    |> cast(attrs, [:spider, :state, :tag, :node, :items_count, :crawl_speed, :run_time])
    |> validate_required([:spider, :state, :tag, :node])
  end
end

defmodule CrawlyUI.Manager.Job do
  @moduledoc """
  Schema for jobs table.
  """

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

    has_many :items, CrawlyUI.Manager.Item, on_delete: :delete_all
    has_many :logs, CrawlyUI.Manager.Log, on_delete: :delete_all

    timestamps()
  end

  @doc false
  def changeset(job, attrs) do
    job
    |> cast(attrs, [:spider, :state, :tag, :node, :items_count, :crawl_speed, :run_time])
    |> validate_required([:spider, :state, :tag, :node])
  end
end

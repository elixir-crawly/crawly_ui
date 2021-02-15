defmodule CrawlyUI.Manager.Spider do
  @moduledoc """
  Schema for spiders table.
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "spiders" do
    field :name, :string
    field :start_urls, :string
    field :fields, :string
    field :links_to_follow, :string
    field :rules, :map
    timestamps()
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:name, :start_urls, :fields, :links_to_follow, :rules])
    |> unique_constraint(:unique_name, name: :spiders_name_index)
    |> validate_required([:name])
  end
end

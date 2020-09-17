defmodule CrawlyUIWeb.ItemView do
  use CrawlyUIWeb, :view

  def render_field_value(name, value) when is_list(value) do
    Enum.reduce(value, [], fn v, acc -> [render_field_value(name, v)] ++ acc end)
  end

  def render_field_value("image", value) do
    "<img width='150px' src='#{value}' />"
  end

  def render_field_value(_name, value) do
    is_url = String.contains?(value, "http://") or String.contains?(value, "https://")

    case is_url do
      true ->
        "<a target='blank' href='#{value}'>#{value}</a>"

      false ->
        "#{value}"
    end
  end
end

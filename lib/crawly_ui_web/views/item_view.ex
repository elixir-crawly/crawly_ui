defmodule CrawlyUIWeb.ItemView do
  use CrawlyUIWeb, :view

  def render_field_value(name, value) when is_list(value) do
    Enum.reduce(value, [], fn v, acc -> [render_field_value(name, v)] ++ acc end)
  end

  def render_field_value("image", value) do
    "<img width='150px' src='#{value}' />"
  end

  def render_field_value(_name, value) do
    is_image = String.ends_with?(value, [".jpeg", ".jpg", ".png"])
    is_url = String.starts_with?(value, ["http://", "https://"])

    cond do
      is_image == true ->
        "<img width='150px' src='#{value}' />"

      is_url == true ->
        "<a target='blank' href='#{value}'>#{value}</a>"

      true ->
        "#{value}"
    end
  end
end

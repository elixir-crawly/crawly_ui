defmodule CrawlyUI.Utils do
  @moduledoc """
  Extract data with complex selector.
  """
  def extract_data_with_complex_selector(document, selector) do
    selector
    |> String.split("//")
    |> do_extract_data_with_complex_selector(document)
  end

  def extract_text(document, selector) do
    Floki.find(document, selector)
    |> Floki.text()
  end

  def extract_text(document, selector, index) do
    Floki.find(document, selector)
    |> Enum.fetch(index)
    |> case do
      :error ->
        ""

      {:ok, element} ->
        Floki.text(element)
    end
  end

  def extract_attribute(document, selector, attribute) do
    Floki.find(document, selector)
    |> Floki.attribute(attribute)
  end

  def extract_attribute(document, selector, attribute, index) do
    Floki.find(document, selector)
    |> Enum.fetch(index)
    |> case do
      :error ->
        ""

      {:ok, element} ->
        Floki.attribute(element, attribute)
        |> List.first()
    end
  end

  defp do_extract_data_with_complex_selector([selector], document) do
    extract_text(document, selector)
  end

  defp do_extract_data_with_complex_selector([selector, index_or_attr], document) do
    case Integer.parse(index_or_attr) do
      :error ->
        extract_attribute(document, selector, index_or_attr)

      {index, _rest} ->
        extract_text(document, selector, index)
    end
  end

  defp do_extract_data_with_complex_selector([selector, index, "text"], document) do
    case Integer.parse(index) do
      :error ->
        ""

      {index, _rest} ->
        extract_text(document, selector, index)
    end
  end

  defp do_extract_data_with_complex_selector([selector, index, attr], document) do
    case Integer.parse(index) do
      :error ->
        ""

      {index, _rest} ->
        extract_attribute(document, selector, attr, index)
    end
  end


  defp do_extract_data_with_complex_selector(_, _document) do
    ""
  end
end

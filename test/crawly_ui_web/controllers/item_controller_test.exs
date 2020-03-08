defmodule CrawlyUIWeb.ItemControllerTest do
  use CrawlyUIWeb.ConnCase

  alias CrawlyUI.Manager

  @create_attrs %{data: %{"url" => "example.com"}}

  def fixture(:item) do
    {:ok, item} = Manager.create_item(@create_attrs)
    item
  end

  describe "index" do
    test "lists all items", %{conn: conn} do
      conn = get(conn, Routes.item_path(conn, :index))
      assert html_response(conn, 200) =~ "Listing Items"
    end
  end

end

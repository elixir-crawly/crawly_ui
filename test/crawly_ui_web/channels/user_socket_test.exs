defmodule CrawlyUIWeb.UserSocketTest do
  use CrawlyUIWeb.ChannelCase, async: true
  alias CrawlyUIWeb.UserSocket

  test "connect to socket" do
    assert {:ok, _} = UserSocket.connect(%{}, UserSocket, %{})
  end

  test "return nil as id" do
    assert nil == UserSocket.id(UserSocket)
  end
end

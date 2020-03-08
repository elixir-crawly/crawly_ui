defmodule ShopsTest do
  use ExUnit.Case
  doctest Shops

  test "greets the world" do
    assert Shops.hello() == :world
  end
end

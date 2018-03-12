defmodule <%= app_module %>Test do
  use ExUnit.Case
  doctest <%= app_module %>

  test "greets the world" do
    assert Starter.hello() == :world
  end
end

defmodule HelloTcpTest do
  use ExUnit.Case
  doctest HelloTcp

  test "greets the world" do
    assert HelloTcp.hello() == :world
  end
end

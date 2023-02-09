defmodule DockerizePhxTest do
  use ExUnit.Case
  doctest DockerizePhx

  test "greets the world" do
    assert DockerizePhx.hello() == :world
  end
end

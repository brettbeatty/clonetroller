defmodule ClonetrollerTest do
  use ExUnit.Case
  doctest Clonetroller

  test "greets the world" do
    assert Clonetroller.hello() == :world
  end
end

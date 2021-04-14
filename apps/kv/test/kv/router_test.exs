defmodule KV.RouterTest do
  use ExUnit.Case, async: true

  @tag :distributed
  test "route requests across nodes" do
    assert KV.Router.route("hello", Kernel, :node, []) == :"foo@kyde-maina"

    assert KV.Router.route("world", Kernel, :node, []) == :"bar@kyde-maina"
  end

  test "raises on unknown entries" do
    assert_raise RuntimeError, ~r/could not find entry/i, fn ->
      KV.Router.route("45", Kernel, :node, [])
    end
  end
end

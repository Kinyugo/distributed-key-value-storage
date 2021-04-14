defmodule KV.RouterTest do
  use ExUnit.Case

  setup do
    current = Application.get_env(:kv, :routing_table, [])

    Application.put_env(:kv, :routing_table, [
      {?a..?m, :"foo@kyde-maina"},
      {?n..?z, :"bar@kyde-maina"}
    ])

    on_exit(fn -> Application.put_env(:kv, :routing_table, current) end)
  end

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

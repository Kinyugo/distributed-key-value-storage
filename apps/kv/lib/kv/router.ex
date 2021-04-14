defmodule KV.Router do
  @doc """
  Dispatch the given `mod`, `fun` and `args` request
  to the appropriate node based on the `bucket`
  """
  def route(bucket, mod, fun, args) do
    # The first byte of the bucket determines
    # which node the request will be routed to.
    first_byte = :binary.first(bucket)

    {_bytes_range, node_name} =
      Enum.find(table(), fn {bytes_range, _node_name} -> first_byte in bytes_range end) ||
        no_entry_error(bucket)

    if node_name == node() do
      apply(mod, fun, args)
    else
      # Send the task to the other node.
      {KV.RouterTasks, node_name}
      |> Task.Supervisor.async(KV.Router, :route, [bucket, mod, fun, args])
      |> Task.await()
    end
  end

  defp no_entry_error(bucket) do
    msg = "Could not find entry for #{inspect(bucket)} in table #{inspect(table())}"
    raise msg
  end

  defp table do
    [{?a..?m, :"foo@kyde-maina"}, {?n..?z, :"bar@kyde-maina"}]
  end
end

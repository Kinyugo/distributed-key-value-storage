defmodule KVServerTest do
  use ExUnit.Case

  @moduletag :capture_log

  setup do
    # Restart the `kv` application on each run
    Application.stop(:kv)
    :ok = Application.start(:kv)
  end

  setup do
    opts = [:binary, packet: :line, active: false]
    {:ok, socket} = :gen_tcp.connect('localhost', 4040, opts)

    %{socket: socket}
  end

  test "server interaction", %{socket: socket} do
    assert send_and_receive(socket, "UNKOWN shopping\r\n") == "UNKOWN COMMAND\r\n"

    assert send_and_receive(socket, "GET shopping eggs\r\n") == "NOT FOUND\r\n"

    assert send_and_receive(socket, "CREATE shopping\r\n") == "OK\r\n"

    assert send_and_receive(socket, "PUT shopping eggs 3\r\n") == "OK\r\n"

    assert send_and_receive(socket, "GET shopping eggs\r\n") == "3\r\n"
    assert send_and_receive(socket, "") == "OK\r\n"

    assert send_and_receive(socket, "DELETE shopping eggs\r\n") == "OK\r\n"

    assert send_and_receive(socket, "GET shopping eggs\r\n") == "\r\n"
    assert send_and_receive(socket, "") == "OK\r\n"
  end

  defp send_and_receive(socket, data) do
    :ok = :gen_tcp.send(socket, data)
    {:ok, data} = :gen_tcp.recv(socket, 0, 1_000)

    data
  end
end

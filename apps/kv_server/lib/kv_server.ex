defmodule KVServer do
  require Logger

  def accept(port) do
    # The options below mean
    #
    # `:binary` - receives data as binaries (instead of lists)
    # `packet: :line` - receives data line by line
    # `active: false` - blocks `:gen.tcp_recv/2` until data is available.
    # `reuseaddr: true` - address is reused if the listener crashes
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    Logger.info("Accepting connections on port: #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(KVServer.TaskSupervisor, fn -> serve(client) end)
    :ok = :gen_tcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    msg =
      with {:ok, data} <- read_line(socket),
           {:ok, command} <-
             KVServer.Command.parse(data) do
        KVServer.Command.run(command)
      end

    write_line(socket, msg)
    serve(socket)
  end

  defp read_line(socket) do
    :gen_tcp.recv(socket, 0)
  end

  defp write_line(socket, {:ok, text}) do
    :gen_tcp.send(socket, text)
  end

  defp write_line(socket, {:error, :unknown_command}) do
    :gen_tcp.send(socket, "UNKOWN COMMAND\r\n")
  end

  defp write_line(socket, {:error, :not_found}) do
    :gen_tcp.send(socket, "NOT FOUND\r\n")
  end

  defp write_line(_socket, {:error, :closed}) do
    # Connection was exited politely.
    exit(:shutdown)
  end

  defp write_line(socket, {:error, error}) do
    # Connection closed unexpectedly.
    :gen_tcp.send(socket, "ERROR!!!\r\n")
    exit(error)
  end
end

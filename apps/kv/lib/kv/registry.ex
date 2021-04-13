defmodule KV.Registry do
  use GenServer

  ## Client API

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  @doc """
  Starts the registry with the given `name`.

  `:name` is always required.
  """
  def start_link(opts) do
    server = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, server, opts)
  end

  @spec lookup(atom | pid | {atom, any} | {:via, atom, any}, any) :: any
  @doc """
  Finds the bucket associated with the given `name`.

  Returns `{:ok, pid}` if bucket exists `:error` otherwise.
  """
  def lookup(server, name) do
    # Perform lookup directly in the ets without accessing the server
    case :ets.lookup(server, name) do
      [{^name, pid}] -> {:ok, pid}
      [] -> :error
    end
  end

  @spec create(atom | pid | {atom, any} | {:via, atom, any}, any) :: any
  @doc """
  Creates a bucket with the given `name` and adds it to the `server`.
  """
  def create(server, name) do
    GenServer.call(server, {:create, name})
  end

  ## Defining  GenServer callbacks

  @impl true
  def init(server) do
    names = :ets.new(server, [:named_table, read_concurrency: true])
    refs = %{}

    {:ok, {names, refs}}
  end

  @impl true
  def handle_call({:create, name}, _from, {names, refs}) do
    case lookup(names, name) do
      {:ok, pid} ->
        {:reply, pid, {names, refs}}

      :error ->
        {:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)
        ref = Process.monitor(pid)

        :ets.insert(names, {name, pid})
        refs = Map.put(refs, ref, name)

        {:reply, pid, {names, refs}}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    :ets.delete(names, name)

    {:noreply, {names, refs}}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end

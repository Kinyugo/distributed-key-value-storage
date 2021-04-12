defmodule KV.Registry do
  use GenServer

  ## Client API

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  @doc """
  Starts the registry.
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok)
  end

  @spec lookup(atom | pid | {atom, any} | {:via, atom, any}, any) :: any
  @doc """
  Finds the bucket associated with the given `name`.

  Returns `{:ok, pid}` if bucket exists `:error` otherwise.
  """
  def lookup(server, name) do
    GenServer.call(server, {:lookup, name})
  end

  @spec create(atom | pid | {atom, any} | {:via, atom, any}, any) :: any
  @doc """
  Creates a bucket with the given `name` and adds it to the `server`.
  """
  def create(server, name) do
    GenServer.cast(server, {:create, name})
  end

  ## Defining  GenServer callbacks

  @impl true
  def init(:ok) do
    {:ok, %{}}
  end

  @impl true
  def handle_call({:lookup, name}, _from, names) do
    {:reply, Map.fetch(names, name), names}
  end

  @impl true
  def handle_cast({:create, name}, names) do
    if Map.has_key?(names, name) do
      {:noreply, names}
    else
      {:ok, bucket} = KV.Bucket.start_link([])
      {:noreply, Map.put(names, name, bucket)}
    end
  end
end

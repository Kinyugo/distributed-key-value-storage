defmodule KV.RegistryTest do
  use ExUnit.Case, async: true

  setup context do
    _ = start_supervised!({KV.Registry, name: context.test})
    %{registry: context.test}
  end

  test "spawns buckets", %{registry: registry} do
    assert KV.Registry.lookup(registry, "shopping") == :error

    KV.Registry.create(registry, "shopping")
    assert {:ok, bucket} = KV.Registry.lookup(registry, "shopping")

    KV.Bucket.put(bucket, "milk", 1)
    assert KV.Bucket.get(bucket, "milk") == 1
  end

  test "removes a bucket on exit", %{registry: registry} do
    KV.Registry.create(registry, "shopping")
    {:ok, bucket} = KV.Registry.lookup(registry, "shopping")

    Agent.stop(bucket)
    # Send a synchronous call to ensure that the :DOWN message has already been processed
    _ = KV.Registry.create(registry, "bogus")
    assert KV.Registry.lookup(registry, "shopping") == :error
  end

  test "removes a bucket on crash", %{registry: registry} do
    KV.Registry.create(registry, "shopping")
    {:ok, bucket} = KV.Registry.lookup(registry, "shopping")

    # Stop the bucket with a non normal reason
    Agent.stop(bucket, :shutdown)
    # Send a synchronous call to ensure that the :DOWN message has already been processed
    _ = KV.Registry.create(registry, "bogus")
    assert KV.Registry.lookup(registry, "shopping") == :error
  end

  test "bucket can crash at any time", %{registry: registry} do
    KV.Registry.create(registry, "shopping")
    {:ok, bucket} = KV.Registry.lookup(registry, "shopping")

    # Simulate a bucket crash
    Agent.stop(bucket, :shutdown)

    # Now trying to call the dead process causes a :noproc exit
    catch_exit(KV.Bucket.put(bucket, "milk", 3))
  end
end

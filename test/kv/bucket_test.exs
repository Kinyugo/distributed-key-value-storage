defmodule KV.BucketTest do
  use ExUnit.Case, async: true

  setup do
    bucket = start_supervised!(KV.Bucket)
    %{bucket: bucket}
  end

  test "stores value by key", %{bucket: bucket} do
    assert KV.Bucket.get(bucket, "milk") == nil

    KV.Bucket.put(bucket, "milk", 5)
    assert KV.Bucket.get(bucket, "milk") == 5
  end

  test "deletes value by key", %{bucket: bucket} do
    KV.Bucket.put(bucket, "milk", 5)
    assert KV.Bucket.delete(bucket, "milk") == 5
    assert KV.Bucket.get(bucket, "milk") == nil
  end
end

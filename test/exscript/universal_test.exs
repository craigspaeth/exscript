defmodule ExScript.Compile.UniversalTest do
  use ExUnit.Case
  import ExScript.Universal

  test "awaits a task" do
    two = await Task.async fn ->
      1 + 1
    end
    assert two == 2
  end

  test "no-ops a value" do
    two = await 1 + 1
    assert two == 2
  end
end

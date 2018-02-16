defmodule ExScript.Stdlib.MapTest do
  use ExUnit.Case

  test "implements Map.merge/2" do
    ExScript.TestHelper.compare_eval("""
      Map.merge %{a: "b"}, %{c: "d"}
    """)
  end
end

defmodule ExScript.Stdlib.MapTest do
  use ExUnit.Case

  test "implements Map.merge/2" do
    ExScript.TestHelper.compare_eval("""
      Map.merge %{a: "b"}, %{c: "d"}
    """)
  end

  test "implements Map.put/2" do
    ExScript.TestHelper.compare_eval("""
      Map.put %{a: "b"}, :a, "c"
    """)
  end
end

defmodule ExScript.Stdlib.StringTest do
  use ExUnit.Case

  test "implements String.split/2" do
    ExScript.TestHelper.compare_eval("""
      String.split "a,b,c", ","
    """)
  end

  @tag :skip
  test "implements String.to_atom/2" do
    ExScript.TestHelper.compare_eval("""
      String.to_atom "a"
    """)
  end
end

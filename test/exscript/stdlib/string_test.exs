defmodule ExScript.Stdlib.StringTest do
  use ExUnit.Case

  test "implements String.split/2" do
    ExScript.TestHelper.compare_eval("""
      String.split "a,b,c", ","
    """)
  end

  test "implements String.replace/3" do
    ExScript.TestHelper.compare_eval("""
      String.replace "foobar", "bar", "baz"
    """)
  end

  @tag :skip
  test "implements String.to_atom/2" do
    ExScript.TestHelper.compare_eval("""
      String.to_atom "a"
    """)
  end
end

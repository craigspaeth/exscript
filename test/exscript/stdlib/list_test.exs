defmodule ExScript.Stdlib.ListTest do
  use ExUnit.Case

  test "implements List.first/1" do
    ExScript.TestHelper.compare_eval("""
      List.first [2,1]
    """)
  end

  test "implements List.delete_at/2" do
    ExScript.TestHelper.compare_eval("""
      List.delete_at [1,2,3], 1
    """)
  end

  test "implements List.replace_at/2" do
    ExScript.TestHelper.compare_eval("""
      List.replace_at [1,2,3], 1, 1
    """)
  end
end

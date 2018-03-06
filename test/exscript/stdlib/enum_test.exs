defmodule ExScript.Stdlib.EnumTest do
  use ExUnit.Case

  test "implements Enum.map/2" do
    ExScript.TestHelper.compare_eval("""
      Enum.map [1,2,3], fn (i) -> 1 + 1 end
    """)
  end

  test "implements Enum.reduce/3" do
    ExScript.TestHelper.compare_eval("""
      Enum.reduce [1,2,3], 4, fn (i, acc) -> i + acc end
    """)
    ExScript.TestHelper.compare_eval("""
      Enum.reduce %{a: "b", b: "c"}, [], fn ({k,v}, acc) -> acc ++ [k] end
    """)
  end

  test "implements Enum.join/2" do
    ExScript.TestHelper.compare_eval("""
      Enum.join ["a", "b", "c"], ","
    """)
  end

  test "implements Enum.at/2" do
    ExScript.TestHelper.compare_eval("""
      Enum.at [0,1,3], 1
    """)
  end

  test "implements Enum.member?/2" do
    ExScript.TestHelper.compare_eval("""
      Enum.member? [0,1,2], 1
    """)
    ExScript.TestHelper.compare_eval("""
      Enum.member? [0,1,2], 4
    """)
  end

  test "implements Enum.with_index?/2" do
    ExScript.TestHelper.compare_eval("""
      for {el, index} <- Enum.with_index([0,1,2]) do
        [el, index]
      end
    """)
  end

  test "implements Enum.reverse/1" do
    ExScript.TestHelper.compare_eval("""
      Enum.reverse [1,2]
    """)
  end
end

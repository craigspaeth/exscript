defmodule ExScript.Stdlib.KernelTest do
  use ExUnit.Case

  test "implements Keyword.has_key?" do
    ExScript.TestHelper.compare_eval("""
      Kernel.is_tuple {1,2}
    """)
  end

  test "implements Keyword.is_atom?" do
    ExScript.TestHelper.compare_eval("""
      Kernel.is_atom :a
    """)
  end

  test "implements Keyword.is_bitstring?" do
    ExScript.TestHelper.compare_eval("""
      Kernel.is_bitstring "a"
    """)
  end

  test "implements Keyword.is_list?" do
    ExScript.TestHelper.compare_eval("""
      Kernel.is_list [1, 2]
    """)
  end

  test "implements Keyword.is_map?" do
    ExScript.TestHelper.compare_eval("""
      Kernel.is_map %{}
    """)

    ExScript.TestHelper.compare_eval("""
      Kernel.is_map 1
    """)
  end

  test "is_nil" do
    ExScript.TestHelper.compare_eval("""
    Kernel.is_nil(nil)
    """)

    ExScript.TestHelper.compare_eval("""
    Kernel.is_nil(nil)
    """)
  end
end

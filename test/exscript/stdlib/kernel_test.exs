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
end

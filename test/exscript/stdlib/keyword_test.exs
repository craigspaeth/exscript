defmodule ExScript.Stdlib.KeywordTest do
  use ExUnit.Case

  test "implements Keyword.has_key?" do
    ExScript.TestHelper.compare_eval("""
      Keyword.has_key? [a: "b"], :a
    """)
    ExScript.TestHelper.compare_eval("""
      Keyword.has_key? [a: "b"], :b
    """)
  end

  test "implements Keyword.merge/2" do
    ExScript.TestHelper.compare_eval("""
      val = Keyword.merge [a: "b"], [b: "c"]
      for {k, v} <- val do
        [Atom.to_string(k), v]
      end
    """)
  end

  test "implements Keyword.get/2" do
    ExScript.TestHelper.compare_eval("""
      Keyword.get [a: 1, a: 2], :a
    """)
  end

  test "implements Keyword.keyword?/1" do
    ExScript.TestHelper.compare_eval("""
      Keyword.keyword?([a: "b"])
    """)
    ExScript.TestHelper.compare_eval("""
      Keyword.keyword?([[:a, "b"]])
    """)
    ExScript.TestHelper.compare_eval("""
      Keyword.keyword?([:a, "b"])
    """)
    ExScript.TestHelper.compare_eval("""
      Keyword.keyword?(nil)
    """)
  end
end

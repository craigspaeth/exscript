defmodule ExScript.Stdlib.AtomTest do
  use ExUnit.Case

  @tag :skip
  test "implements Atom.to_string/1" do
    ExScript.TestHelper.compare_eval("""
      Atom.to_string :a
    """)
  end
end

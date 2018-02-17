defmodule ExScript.Compiler.ComprehensionsTest do
  use ExUnit.Case

  test "compiles comprehensions" do
    ExScript.TestHelper.compare(
      """
      c = [1, 2]
      b = for a <- c do
        a + 1
      end
      """,
      """
      let c, b;
      c = [
          1,
          2
      ];
      b = c.map(a => {
          return a + 1;
      });
      """
    )
  end

  test "compiles right-hand expressions" do
    ExScript.TestHelper.compare(
      """
      for i <- Map.to_list(%{a: 1}) do
        i
      end
      """,
      """
      Map.to_list({ a: 1 }).map(i => {
          return i;
      });
      """
    )
  end

  test "compiles nested pattern match" do
    ExScript.TestHelper.compare(
      """
      for {{k, v}, index} <- Enum.with_index(%{a: "b"}) do
        k
      end
      """,
      """
      Enum.with_index({ a: 'b' }).map(([[k, v], index]) => {
          return k;
      });
      """
    )
  end

  test "compiles hoisted variables in comprehensions" do
    ExScript.TestHelper.compare(
      """
      for i <- [1,2] do
        a = "b" <> i
      end
      """,
      """
      [
          1,
          2
      ].map(i => {
          let a;
          a = 'b' + i;
          return a;
      });
      """
    )
  end
end

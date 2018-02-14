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
end

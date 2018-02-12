defmodule ExScript.Compiler.ComprehensionsTest do
  @moduledoc false

  use ExUnit.Case, async: true

  test "compiles comprehensions" do
    ast = Code.string_to_quoted! """
    c = [1, 2]
    b = for a <- c do
      a + 1
    end
    """
    js = ExScript.Compile.to_js! ast
    assert js <> "\n" == """
    const c = [
        1,
        2
    ];;
    const b = c.map(a => {
        return a + 1;
    });;
    """
  end
end

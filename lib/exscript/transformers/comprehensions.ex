defmodule ExScript.Transformers.Comprehensions do
  @moduledoc """
  Transforms module (and module-related) Elixir ASTs to ESTree JSON
  """

  alias ExScript.Compile, as: Compile
  alias ExScript.Common, as: Common

  def transform_comprehension({_, _, for_ast} = ast) do
    [{_, _, [left, enum]}, [do: block]] = for_ast
    %{
      type: "CallExpression",
      callee: %{
        type: "MemberExpression",
        object: Compile.transform!(enum),
        property: %{
          type: "Identifier",
          name: "map"
        }
      },
      arguments: [Common.function_expression(:arrow, [left], block)]
    }
  end
end

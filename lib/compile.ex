defmodule Compiler do
  
  def compile(ast) do
    ast |> to_js_ast |> js_ast_to_js
  end

  defp to_js_ast(ast) do
    {token, metadata, args} = ast
    node = case token do
      :+ ->
        [left, right] = args
        %{
          type: "BinaryExpression",
          operator: "+",
          left: %{type: "Literal", value: left},
          right: %{type: "Literal", value: right}
        }
      _ ->
        raise "Unknown token #{token}"
    end
    node
  end

  defp js_ast_to_js(ast) do
    code =
      "process.stdout.write(" <>
      "require('escodegen').generate(#{Poison.encode! ast})" <>
      ")"
    {result, _} = System.cmd "node", ["-e", code]
    result
  end
end
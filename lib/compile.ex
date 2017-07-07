defmodule Compiler do
  
  def compile(ast) do
    ast |> to_js_ast |> js_ast_to_js
  end

  defp to_js_ast(ast) do
    {token, metadata, args} = ast
    node = cond do
      token == :+ or token == :* ->
        [left, right] = args
        %{
          type: "BinaryExpression",
          operator: token,
          left: %{type: "Literal", value: left},
          right: cond do
            is_integer right -> %{type: "Literal", value: right} 
            is_tuple right -> to_js_ast right
            true -> raise "Uknown right-hand expression #{right}"
          end
        }
      true ->
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
defmodule ExScript.Compile do

  def compile!(ast) do
    File.read!("lib/exscript/lib.js") <> to_js! ast
  end

  def to_js!(ast) do
    code =
      "process.stdout.write(" <>
      "require('escodegen').generate(#{Poison.encode! to_js_ast! ast})" <>
      ")"
    {result, _} = System.cmd "node", ["-e", code]
    result
  end

  defp to_js_ast!(ast) do
    cond do
      is_tuple ast ->
        transform_non_literal! ast
      is_integer(ast) or is_boolean(ast) or is_binary(ast) or is_nil(ast) ->
        %{type: "Literal", value: ast}
      is_atom ast ->
        %{
          type: "ExpressionStatement",
          expression: %{
            type: "CallExpression",
            callee: %{type: "Identifier", name: "Symbol"},
            arguments: [%{type: "Literal", value: ast}]
          }
        }
      is_list ast ->
        %{
          type: "ArrayExpression",
          elements: Enum.map(ast, &to_js_ast!(&1))
        }
      true ->
        raise "Unknown AST #{ast}"
    end
  end

  defp transform_non_literal!({token, _, args} = ast) do
    cond do
      token == :%{} ->
        transform_map ast
      token == := ->
        transform_assignment ast
      token in [:+, :*, :/, :-, :==] ->
        transform_binary_expression ast
      String.starts_with? to_string(token), "is_" ->
        transform_identifying_function ast
      token == :fn ->
        transform_anonymous_function ast
      token == :__block__ ->
        transform_block_statement ast
      is_atom(token) and args == nil ->
        transform_return_statement ast
      true ->
        raise "Unknown token #{token}"
    end
  end

  defp transform_binary_expression({token, _, [left, right]}) do
    %{
      type: "BinaryExpression",
      operator: (if token == :==, do: "===", else: token),
      left: to_js_ast!(left),
      right: to_js_ast!(right)
    }
  end

  def transform_identifying_function({token, _, args}) do
    %{
      type: "ExpressionStatement",
      expression: %{
        type: "CallExpression",
        callee: %{
          type: "MemberExpression",
          object: %{type: "Identifier", name: "ExScript"},
          property: %{type: "Identifier", name: token}
        },
        arguments: Enum.map(args, &to_js_ast!(&1))
      }
    }
  end

  defp transform_anonymous_function({_, _, args}) do
    fn_args = for {_, _, fn_args} <- args, do: fn_args
    [return_val | fn_args] = fn_args |> List.flatten |> Enum.reverse
    %{
      type: "ExpressionStatement",
      expression: %{
        type: "ArrowFunctionExpression",
        expression: true,
        params: Enum.map(fn_args, fn ({var_name, _, _}) ->
          %{type: "Identifier", name: var_name}
        end),
        body: to_js_ast!(return_val)
      }
    }
  end

  defp transform_block_statement({_, _, args}) do
    %{
      type: "BlockStatement",
      body: Enum.map(args, &to_js_ast!(&1))
    }
  end

  defp transform_return_statement({token, _, _}) do
    %{
      type: "ReturnStatement",
      argument: %{
        type: "Identifier",
        name: token
      }
    }
  end

  defp transform_assignment({_, _, args}) do
    [{var_name, _, _}, val]= args
    %{
      type: "VariableDeclaration",
      kind: "const",
      declarations: [
        %{
          type: "VariableDeclarator",
          id: %{type: "Identifier", name: var_name},
          init: %{type: "Literal", value: val}
        }
      ]
    }
  end

  def transform_map({_, _, args}) do
    %{
      type: "ObjectExpression",
      properties: for {key, val} <- args do
        %{
          type: "Property",
          key: %{type: "Identifier", name: key},
          value: %{type: "Literal", value: val}
        }
      end
    }
  end
end

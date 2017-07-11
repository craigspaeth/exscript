defmodule ExScript.Compile do

  def compile!(ast) do
    File.read!("lib/exscript/lib.js") <> to_js! ast
  end

  def to_js!(ast) do
    code =
      "process.stdout.write(" <>
      "require('escodegen').generate(#{Poison.encode! to_program_ast! ast})" <>
      ")"
    {result, _} = System.cmd "node", ["-e", code]
    result
  end

  defp to_program_ast!(ast) do
    if is_tuple(ast) and Enum.at(Tuple.to_list(ast), 0) == :__block__ do
      {_, _, body} = ast
      body = Enum.map body, fn (ast) -> 
        %{type: "ExpressionStatement", expression: transform!(ast)}
      end
      %{type: "Program", body: body}
    else
      transform! ast
    end
  end

  defp transform!(ast) do
    cond do
      is_tuple ast ->
        {token, _, _} = ast
        if is_tuple token do
          transform_function_call! ast
        else
          transform_non_literal! ast
        end
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
          elements: Enum.map(ast, &transform!(&1))
        }
      true ->
        raise "Unknown AST #{ast}"
    end
  end

  defp transform_non_literal!({token, _, args} = ast) do
    cond do
      token == :if ->
        transform_if ast
      token == :cond ->
        transform_cond ast
      token == :%{} ->
        transform_map ast
      token == := ->
        transform_assignment ast
      token in [:+, :*, :/, :-, :==, :<>] ->
        transform_binary_expression ast
      String.starts_with? to_string(token), "is_" ->
        transform_identifying_function ast
      token == :fn ->
        transform_anonymous_function ast
      token == :__block__ ->
        transform_block_statement ast
      is_atom(token) and args == nil ->
        %{type: "Identifier", name: token}
      token == :defmodule ->
        transform_module ast
      token == :++ ->
        transform_array_concat_operator ast
      true ->
        raise "Unknown token #{token}"
    end
  end

  defp transform_binary_expression({token, _, [left, right]}) do
    %{
      type: "BinaryExpression",
      operator: case token do
        :== -> "==="
        :<> -> "+"
        _ -> token
      end,
      left: transform!(left),
      right: transform!(right)
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
        arguments: Enum.map(args, &transform!(&1))
      }
    }
  end

  defp transform_anonymous_function({_, _, args}) do
    fn_args = for {_, _, fn_args} <- args, do: fn_args
    [return_val | fn_args] = fn_args |> List.flatten |> Enum.reverse
    js_function_ast fn_args, return_val
  end

  defp transform_block_statement({_, _, args}) do
    %{
      type: "BlockStatement",
      body: Enum.map(args, &transform!(&1))
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
          init: transform! val
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

  def transform_module({_, _, args}) do
    [{_, _, namespaces} | [body]] = args
    [{_, method_or_methods} | _] = body
    {key, _, _} = method_or_methods
    methods = if key == :__block__ do
      {_, _, methods} = method_or_methods
      methods
    else
      [method_or_methods]
    end
    namespace = Enum.join namespaces, ""
    %{
      type: "AssignmentExpression",
      operator: "=",
      left: %{
        type: "MemberExpression",
        object: %{
          type: "MemberExpression",
          object: %{type: "Identifier", name: "ExScript"},
          property: %{type: "Identifier", name: "Modules"}
        },
        property: %{type: "Identifier", name: namespace}
      },
      right: %{
        type: "ObjectExpression",
        properties: for method <- methods do
          {_, _, body} = method
          [{method_name, _, args}, [{_, return_val}]] = body
          %{
            type: "Property",
            method: false,
            shorthand: false,
            computed: false,
            key: %{type: "Identifier", name: method_name},
            value: js_function_ast(args, return_val)
          }
        end
      }
    }
  end

  defp transform_array_concat_operator({_, _, args}) do
    [left_arr, right_arr] = args
    %{
      type: "CallExpression",
      callee: %{
        type: "MemberExpression",
        property: %{type: "Identifer", name: "concat"},
        object: transform!(left_arr)
      },
      arguments: [transform!(right_arr)]
    }
  end

  def transform_function_call!(ast) do
    {{_, _, [{_, _, namespaces}, property]}, _, args} = ast
    namespace = Enum.join namespaces, ""
    %{
      type: "CallExpression",
      arguments: Enum.map(args, &transform!(&1)),
      callee: %{
        type: "MemberExpression",
        object: %{
          type: "MemberExpression",
          object: %{
            type: "MemberExpression",
            object: %{type: "Identifier", name: "ExScript"},
            property: %{type: "Identifier", name: "Modules"}
          },
          property: %{type: "Identifier", name: namespace}
        },
        property: %{type: "Identifier", name: property}
      }
    }
  end

  defp transform_if({_, _, [test, [{_, consequent}, {_, alternate}]]}) do
    %{
      type: "ConditionalExpression",
      test: transform!(test),
      consequent: transform!(consequent),
      alternate: transform!(alternate)
    }
  end

  defp transform_cond(ast) do
    {_, _, [[{_, clauses}]]} = ast
    for {_, _, [condition, body]} <- clauses do
      transform! ast
    end
    %{
    }
  end

  defp js_function_ast(args, return_val) do
    body = cond do
      is_tuple return_val ->
        {key, _, body} = return_val
        case key do
          :__block__ ->
            [return_line | fn_lines] = Enum.reverse body
            Enum.map(fn_lines, &transform!(&1)) ++
            [%{type: "ReturnStatement", argument: transform!(return_line)}]
          _ ->
            [%{type: "ReturnStatement", argument: transform!(return_val)}]            
        end
      true ->
        [%{type: "ReturnStatement", argument: transform!(return_val)}]
    end
    args = args || []
    %{
      type: "ArrowFunctionExpression",
      generator: false,
      expression: false,
      params: Enum.map(args, fn ({var_name, _, _}) ->
        %{type: "Identifier", name: var_name}
      end),
      body: %{type: "BlockStatement", body: body}
    }
  end
end

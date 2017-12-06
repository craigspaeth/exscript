defmodule ExScript.Compile do

  def compile!(code) do
    Code.compile_string code
    ast = Code.string_to_quoted! code
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
    IO.inspect ast
    cond do
      is_tuple ast ->
        {token, _, _} = ast
        cond do
          is_tuple token ->
            {token, _, parent} = token
            case parent do
              {:__aliases__, _,} ->
                transform_external_function_call ast
              _ ->
                transform_property_access ast
            end
          true ->
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
      token == :case ->
        transform_case ast
      token == :|> ->
        transform_pipeline ast
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
      token == :defmodule ->
        transform_module ast
      token == :++ ->
        transform_array_concat_operator ast
      args == nil ->
        %{type: "Identifier", name: token}
      is_list(args) ->
        transform_local_function_call ast
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
      type: "CallExpression",
      callee: %{
        type: "MemberExpression",
        object: %{type: "Identifier", name: "ExScript"},
        property: %{type: "Identifier", name: token}
      },
      arguments: Enum.map(args, &transform!(&1))
    }
  end

  defp transform_anonymous_function({_, _, args}) do
    fn_args = for {_, _, fn_args} <- args, do: fn_args
    [return_val | fn_args] = fn_args |> List.flatten |> Enum.reverse
    function_expression :arrow, fn_args, return_val
  end

  defp transform_block_statement({_, _, args}) do
    %{
      type: "BlockStatement",
      body: Enum.map(args, &transform!(&1))
    }
  end

  defp transform_assignment({_, _, args}) do
    [vars, val] = args
    id = if is_list(vars) do
      {var_name, _, _} = Enum.at vars, 0
      %{
        type: "ArrayPattern",
        elements: if var_name == :| do
          {var_name, _, body} = Enum.at vars, 0
          [{head_var_name, _, _}, {tail_var_name, _, _}] = body
          [
            %{type: "Identifier", name: head_var_name},
            %{
              type: "RestElement",
              argument: %{type: "Identifier", name: tail_var_name}
            }
          ]
        else
          for {var_name, _, _} <- vars do
            %{type: "Identifier", name: var_name}
          end
        end
      }
    else
      {var_name, _, _} = vars
      %{type: "Identifier", name: var_name}
    end
    %{
      type: "VariableDeclaration",
      kind: "const",
      declarations: [
        %{
          type: "VariableDeclarator",
          id: id,
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
            method: true,
            shorthand: false,
            computed: false,
            key: %{type: "Identifier", name: method_name},
            value: function_expression(:obj, args, return_val)
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

  defp transform_external_function_call({
    {_, _, [{_, _, namespaces}, property]}, _, args
  }) when not is_nil namespaces do
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

  defp transform_external_function_call({
    {_, _, [{callee_name, _, namespaces}, func_name]}, _, args
  } = ast) when is_nil namespaces do
    %{
      type: "CallExpression",
      arguments: Enum.map(args, &transform!(&1)),
      callee: %{
        type: "MemberExpression",
        arguments: [],
        object: %{
          type: "Identifier",
          name: callee_name
        },
        property: %{
          type: "Identifier",
          name: func_name
        }
      }
    }
  end

  defp transform_property_access({
    {_, _, [_, action]}, _, [owner, prop]
  } = ast) when action == :get do
    %{
      type: "MemberExpression",
      computed: true,
      object: transform!(owner),
      property: transform!(prop)
    }
  end

  defp transform_property_access({
    {_, _, [parent_ast, key]}, _, args
  } = ast) do
    # CHECK HERE
    IO.inspect parent_ast
    if is_list(args) and length(args) > 0 do
      %{
        type: "CallExpression",
        arguments: Enum.map(args, &transform!(&1)),
        callee: %{
          type: "MemberExpression",
          object: transform!(parent_ast),
          property: %{
            type: "Identifier",
            name: "#{key}"
          },
          arguments: []
        }
      }
    else
      %{
        type: "MemberExpression",
        computed: false,
        object: transform!(parent_ast),
        property: %{
          type: "Identifier",
          name: "#{key}"
        }
      }
    end
  end

  defp transform_local_function_call({func_name, _, args}) do
    %{
      type: "CallExpression",
      arguments: Enum.map(args, &transform!(&1)),
      callee: %{
        type: "MemberExpression",
        object: %{
          type: "ThisExpression",
        },
        property: %{
          type: "Identifier",
          name: func_name
        },
        arguments: []
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

  defp transform_cond({_, _, [[{_, clauses}]]}) do
    if_elses = for {_, _, [[condition], body]} <- clauses do
      [
        transform!(condition),
        %{
          type: "BlockStatement",
          body: return_block(body)
        }
      ]
    end
    %{
      type: "CallExpression",
      arguments: [],
      callee: %{
        type: "ArrowFunctionExpression",
        params: [],
        body: %{
          type: "BlockStatement",
          body: [nested_if_statement(if_elses)]
        }
      }
    }
  end

  defp transform_case({_, _, [val, [{_, clauses}]]}) do
    if_elses = for {_, _, [[compare_val], body]} = clause <- clauses do
      is_any = if is_tuple compare_val do
        compare_val
        |> Tuple.to_list
        |> List.first == :_
      end
      [
        (if is_any, do: %{type: "Literal", value: true}, else: %{
          type: "BinaryExpression",
          operator: "===",
          left: transform!(val),
          right: transform!(compare_val)
        }),
        %{
          type: "BlockStatement",
          body: return_block(body)
        }
      ]
    end
    %{
      type: "CallExpression",
      arguments: [],
      callee: %{
        type: "ArrowFunctionExpression",
        params: [],
        body: %{
          type: "BlockStatement",
          body: [nested_if_statement(if_elses)]
        }
      }
    }
  end

  defp transform_pipeline({_, _, [arg, caller]} = ast) do
    IO.inspect caller
    {}
  end

  defp nested_if_statement(if_elses, index \\ 0) do
    if index >= length if_elses do
      nil
    else
      [test, consequent] = Enum.at if_elses, index
      %{
        type: "IfStatement",
        test: test,
        consequent: consequent,
        alternate: nested_if_statement(if_elses, index + 1)
      }
    end
  end

  defp function_expression(type, args, return_val) do
    args = args || []
    %{
      type: case type do
        :arrow -> "ArrowFunctionExpression"
        :obj -> "FunctionExpression"
      end,
      params: Enum.map(args, fn ({var_name, _, _}) ->
        %{type: "Identifier", name: var_name}
      end),
      body: %{type: "BlockStatement", body: return_block(return_val)}
    }
  end

  defp return_block(ast) do
    cond do
      is_tuple ast ->
        {key, _, body} = ast
        case key do
          :__block__ ->
            [return_line | fn_lines] = Enum.reverse body
            Enum.map(fn_lines, &transform!(&1)) ++
            [%{type: "ReturnStatement", argument: transform!(return_line)}]
          _ ->
            [%{type: "ReturnStatement", argument: transform!(ast)}]
        end
      true ->
        [%{type: "ReturnStatement", argument: transform!(ast)}]
    end
  end
end

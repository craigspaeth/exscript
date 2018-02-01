defmodule ExScript.Compile do
  import ExScript.Transformers.Modules
  import ExScript.Transformers.Comprehensions

  @js_lib File.read!("lib/exscript/lib.js")
  @cwd File.cwd!


  def compile!(code) do
    Code.compile_string code
    ast = Code.string_to_quoted! code
    @js_lib <> to_js! ast
  end

  def to_js!(ast) do
    code =
      "process.stdout.write(" <>
      "require('escodegen').generate(#{Poison.encode! to_program_ast! ast})" <>
      ")"
    {result, _} = System.cmd "node", ["-e", code], cd: @cwd
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

  def transform!(ast) do
    cond do
      is_tuple ast ->
        try do
          {token, _, _} = ast
          cond do
            is_tuple token ->
              {_, _, parent} = token
              case parent do
                {:__aliases__, _, _} ->
                  transform_external_function_call ast
                [{:__aliases__, _, _}, _] ->
                  transform_external_function_call ast
                _ ->
                  transform_property_access ast
              end
            token == :__aliases__ ->
              transform_module_reference ast
            token == :@ ->
              transform_module_attribute ast
            token == :for ->
              transform_comprehension ast
            true ->
              transform_non_literal ast
          end
        rescue
          MatchError -> transform_tuple_literal ast
        end
      is_integer(ast) or is_boolean(ast) or is_binary(ast) or is_nil(ast) ->
        %{type: "Literal", value: ast}
      is_atom ast ->
        %{
          type: "CallExpression",
          callee: %{type: "Identifier", name: "Symbol"},
          arguments: [%{type: "Literal", value: ast}]
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

  def transform_list(list) do
    list
    |> Enum.map(&transform!(&1))
    |> Enum.reject(&is_nil/1)
  end

  defp transform_non_literal({token, callee, args} = ast) do
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
      token == :not ->
        transform_not_operator ast
      token in [:+, :*, :/, :-, :==, :<>, :and, :or, :||, :&&, :!=, :>] ->
        transform_binary_expression ast
      token == :++ ->
        transform_array_concat_operator ast
      token == :<<>> ->
        transform_string_interpolation ast
      callee[:import] == Kernel or Kernel.__info__(:functions)
      |> Keyword.keys
      |> Enum.member?(token) ->
        transform_kernel_function ast
      token == :fn ->
        transform_anonymous_function ast
      token == :__block__ ->
        transform_block_statement ast
      token == :defmodule ->
        transform_module ast
      args == nil ->
        %{type: "Identifier", name: token}
      is_list(args) ->
        transform_local_function ast
      true ->
        raise "Unknown token #{token}"
    end
  end

  defp transform_tuple_literal(ast) do
    %{
      type: "NewExpression",
      callee: %{
        type: "MemberExpression",
        object: %{
          type: "MemberExpression",
          object: %{
            type: "Identifier",
            name: "ExScript"
          },
          property: %{
            type: "MemberExpression",
            name: "Types"
          }
        },
        property: %{
          type: "MemberExpression",
          name: "Tuple"
        }
      },
      arguments: ast
        |> Tuple.to_list
        |> Enum.map(&transform!(&1))
    }
  end

  defp transform_binary_expression({token, _, [left, right]}) do
    %{
      type: "BinaryExpression",
      operator: case token do
        :!= -> "!=="
        :== -> "==="
        :<> -> "+"
        :and -> "&&"
        :or -> "||"
        :not -> "!"
        _ -> token
      end,
      left: transform!(left),
      right: transform!(right)
    }
  end

  defp transform_kernel_function({fn_name, _, args}) do
    module_function_call "Kernel", fn_name, args
  end

  defp transform_anonymous_function({_, _, args}) do
    fn_args = for {_, _, fn_args} <- args, do: fn_args
    [return_val | fn_args] = fn_args |> List.flatten |> Enum.reverse
    function_expression :arrow, Enum.reverse(fn_args), return_val
  end

  defp transform_block_statement({_, _, args}) do
    %{
      type: "BlockStatement",
      body: transform_list args
    }
  end

  defp transform_assignment({_, _, args}) do
    [vars, val] = args
    vars = if is_tuple(vars) and is_tuple(List.first(Tuple.to_list(vars))) do
      Tuple.to_list(vars)
    else
      vars
    end
    id = if is_list(vars) do
      {var_name, _, _} = Enum.at vars, 0
      %{
        type: "ArrayPattern",
        elements: if var_name == :| do
          {_, _, body} = Enum.at vars, 0
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

  defp transform_not_operator({_, _, [val]}) do
    %{
      type: "UnaryExpression",
      operator: "!",
      argument: transform! val
    }
  end

  defp transform_map({_, _, args}) do
    %{
      type: "ObjectExpression",
      properties: for {key, val} <- args do
        %{
          type: "Property",
          key: %{type: "Identifier", name: key},
          value: transform!(val)
        }
      end
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
    {_, _, [{_, _, namespaces}, fn_name]}, _, args
  }) when not is_nil namespaces do
    mod_name = Enum.join namespaces, ""
    module_function_call mod_name, fn_name, args
  end

  defp transform_external_function_call({
    {_, _, [{callee_name, _, namespaces}, fn_name]}, _, args
  }) when is_nil namespaces do
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
          name: fn_name
        }
      }
    }
  end

  defp transform_property_access({
    {_, _, [_, action]}, _, [owner, prop]
  }) when action == :get do
    %{
      type: "MemberExpression",
      computed: true,
      object: transform!(owner),
      property: transform!(prop)
    }
  end

  defp transform_property_access({
    {_, _, [Kernel, key]}, _, args
  }) do
    %{
      type: "CallExpression",
      callee: %{
        type: "MemberExpression",
        object: %{type: "Identifier", name: "ExScript"},
        property: %{type: "Identifier", name: key}
      },
      arguments: Enum.map(args, &transform!(&1))
    }
  end

  defp transform_property_access({
    {_, _, [{_, _, [mod_name]}, key]}, _, args
  }) do
    module_function_call mod_name, key, args
  end

  defp transform_property_access({
    {_, _, [{_, _, _} = parent_ast, key]}, _, args
  }) when length(args) == 0 do
    %{
      type: "MemberExpression",
      object: transform!(parent_ast),
      property: %{
        type: "Identifier",
        name: key
      }
    }
  end

  defp transform_property_access({
    {_, _, [{_, _, _} = parent_ast, key]}, _, args
  }) do
    %{
      type: "CallExpression",
      arguments: Enum.map(args, &transform!(&1)),
      callee: %{
        type: "MemberExpression",
        object: transform!(parent_ast),
        property: %{
          type: "Identifier",
          name: key
        }
      }
    }
  end

  defp transform_property_access({
    {_, _, [{callee, _, _}]}, _, args
  }) do
    %{
      type: "CallExpression",
      arguments: Enum.map(args, &transform!(&1)),
      callee: %{
        type: "Identifier",
        name: callee
      }
    }
  end

  defp transform_if({_, _, [test, [{_, consequent}, {_, alternate}]]}) do
    expr = fn (body) ->
      if is_tuple(body) do
        iife(return_block(body))
      else
        transform!(body)
      end
    end
    %{
      type: "ConditionalExpression",
      test: transform!(test),
      consequent: expr.(consequent),
      alternate: expr.(alternate)
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
    if_elses = for {_, _, [[compare_val], body]} <- clauses do
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

  defp transform_pipeline({_, _, [arg | [fn_call]]}) do
    {{_, _, [{_, _, [mod_name]}, fn_name]}, _, extra_args} = fn_call
    module_function_call(
      mod_name,
      fn_name,
      [arg | extra_args]
    )
  end

  defp transform_string_interpolation({_, _, elements}) do
    els = List.flatten(for el <- elements do
      case el do
        {:::, _, _} ->
          {_, _, [{_, _, [interpolated_ast]}, _]} = el
          if el == List.last elements do
            template_el = %{
              type: "TemplateElement",
              value: %{
                raw: "",
                cooked: ""
              },
              tail: true
            }
            [
              {:expression, transform! interpolated_ast},
              {:quasis, template_el}
            ]
          else
            [{:expression, transform! interpolated_ast}]
          end
        _ ->
          template_el = %{
            type: "TemplateElement",
            value: %{
              raw: el,
              cooked: el
            }
          }
          {:quasis, template_el}
      end
    end)
    expressions = for {:expression, val} <- els, do: val
    quasis = for {:quasis, val} <- els, do: val
    %{
      type: "TemplateLiteral",
      expressions: expressions,
      quasis: quasis
    }
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

  def function_expression(type, args, return_val) do
    args = args || []
    %{
      type: case type do
        :arrow -> "ArrowFunctionExpression"
        :obj -> "FunctionExpression"
      end,
      params: Enum.map(args, fn (ast) ->
        case ast do
          {_, _, [{key_name, {val_name, _, _}}]} ->
            %{
              type: "ObjectPattern",
              properties: [
                %{
                  type: "Property",
                  key: %{
                    type: "Identifier",
                    name: key_name
                  },
                  value: %{
                    type: "Identifier",
                    name: val_name
                  }
                }
              ]
            }
          {{left_name, _, _}, {right_name, _, _}} ->
            %{
              type: "ArrayPattern",
              elements: [
                %{
                  type: "Identifier",
                  name: left_name
                },
                %{
                  type: "Identifier",
                  name: right_name
                }
              ]
            }
          {:{}, _, els} ->
            %{
              type: "ArrayPattern",
              elements: Enum.map(els, fn ({name, _, _}) ->
                %{
                  type: "Identifier",
                  name: name
                }
              end)
            }
          {var_name, _, _} ->
            %{type: "Identifier", name: var_name}
        end
      end),
      body: %{type: "BlockStatement", body: return_block(return_val)}
    }
  end

  def return_block(ast) do
    cond do
      is_tuple ast ->
        {key, _, body} = ast
        case key do
          :__block__ ->
            [return_line | fn_lines] = Enum.reverse body
            Enum.map(Enum.reverse(fn_lines), &transform!(&1)) ++
            dont_return_assignment(return_line)
          _ ->
            dont_return_assignment ast
        end
      true ->
        [%{type: "ReturnStatement", argument: transform!(ast)}]
    end
  end

  defp dont_return_assignment(ast) do
    {key, _, body} = ast
    if key == := do
      [{var_name, _, _}, _] = body
      [
        transform!(ast),
        %{
          type: "ReturnStatement",
          argument: %{type: "Identifier", name: var_name}
        }
      ]
    else
      [%{type: "ReturnStatement", argument: transform!(ast)}]
    end
  end

  defp iife(body) do
    %{
      type: "CallExpression",
      arguments: [],
      callee: %{
        type: "ArrowFunctionExpression",
        params: [],
        body: %{
          type: "BlockStatement",
          body: body
        }
      }
    }
  end
end

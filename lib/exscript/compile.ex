defmodule ExScript.Compile do
  import ExScript.Common
  import ExScript.Transformers.Modules
  import ExScript.Transformers.Comprehensions
  import ExScript.Transformers.Functions
  import ExScript.Transformers.Operators
  import ExScript.Transformers.ControlFlow
  import ExScript.Transformers.Types

  @cwd File.cwd!()

  def compile!(code) do
    app_code =
      code
      |> Code.string_to_quoted!()
      |> to_js!

    """
    (() => {
      #{runtime()}
      #{app_code};
    })()
    """
  end

  def runtime do
    stdlib =
      "#{@cwd}/lib/exscript/stdlib/*.ex"
      |> Path.wildcard()
      |> Enum.map(&File.read!(&1))
      |> Enum.join()
      |> Code.string_to_quoted!()
      |> ExScript.Compile.to_js!()

    Enum.join([
      "class Tup extends Array {};\n",
      stdlib,
      "\n",
      Enum.join(
        for mod_name <- stdlib_module_names() do
          "const #{mod_name} = ExScriptStdlib#{mod_name};\n"
        end
      )
    ])
  end

  def stdlib_module_names do
    "#{@cwd}/lib/exscript/stdlib/*.ex"
    |> Path.wildcard()
    |> Enum.map(
      &(Path.basename(&1)
        |> String.split(".")
        |> List.first()
        |> String.split("_")
        |> Enum.map(fn s -> String.capitalize(s) end)
        |> Enum.join("")
        |> (fn s -> if s in ["Js", "Io"], do: String.upcase(s), else: s end).())
    )
  end

  def to_js!(ast) do
    code =
      "process.stdout.write(" <>
        "require('escodegen').generate(#{Poison.encode!(to_program_ast!(ast))})" <> ")"

    {result, _} = System.cmd("node", ["-e", code], cd: @cwd)
    result
  end

  defp to_program_ast!(ast) do
    ExScript.State.init()

    body =
      if is_tuple(ast) and Enum.at(Tuple.to_list(ast), 0) == :__block__ do
        transform_block_statement(ast)
      else
        transform_block_statement({:__block__, [], [ast]})
      end

    # Single statement
    body =
      if length(ExScript.State.module_defs()) == 0 do
        body

        # Full program
      else
        # Order modules correctly to support compile-time reference
        body =
          for mod_name <- ExScript.State.modules() do
            Enum.find(body, fn js_ast ->
              js_ast_mod_name = List.first(js_ast.declarations).id.name
              js_ast_mod_name == mod_name
            end)
          end
          |> Enum.reject(&is_nil(&1))

        # Attach modules to `window`
        body ++
          [
            %{
              type: "AssignmentExpression",
              operator: "=",
              left: %{
                object: %{
                  arguments: [],
                  callee: %{
                    object: %{name: "ExScriptStdlibJS", type: "Identifier"},
                    property: %{name: "global", type: "Identifier"},
                    type: "MemberExpression"
                  },
                  type: "CallExpression"
                },
                property: %{name: "ExScript", type: "Identifier"},
                type: "MemberExpression"
              },
              right: %{
                type: "ObjectExpression",
                properties:
                  [
                    %{
                      type: "SpreadElement",
                      argument: %{
                        object: %{
                          arguments: [],
                          callee: %{
                            object: %{name: "ExScriptStdlibJS", type: "Identifier"},
                            property: %{name: "global", type: "Identifier"},
                            type: "MemberExpression"
                          },
                          type: "CallExpression"
                        },
                        property: %{name: "ExScript", type: "Identifier"},
                        type: "MemberExpression"
                      }
                    }
                  ] ++
                    for mod_name <- ExScript.State.modules() do
                      %{
                        type: "Property",
                        key: %{name: mod_name, type: "Identifier"},
                        value: %{
                          alternate: %{name: mod_name, type: "Identifier"},
                          consequent: %{raw: "null", type: "Literal", value: nil},
                          test: %{
                            left: %{
                              argument: %{name: mod_name, type: "Identifier"},
                              operator: "typeof",
                              prefix: true,
                              type: "UnaryExpression"
                            },
                            operator: "===",
                            right: %{
                              raw: "\"undefined\"",
                              type: "Literal",
                              value: "undefined"
                            },
                            type: "BinaryExpression"
                          },
                          type: "ConditionalExpression"
                        }
                      }
                    end
              }
            }
          ]
      end

    ExScript.State.clear()
    %{type: "Program", body: body}
  end

  def transform!(ast) do
    cond do
      is_tuple(ast) ->
        try do
          {token, _, _} = ast

          cond do
            is_tuple(token) ->
              {_, _, parent} = token

              case parent do
                {:__aliases__, _, _} ->
                  transform_external_function_call(ast)

                [{:__aliases__, _, _}, _] ->
                  transform_external_function_call(ast)

                _ ->
                  transform_property_access(ast)
              end

            true ->
              transform_non_literal(ast)
          end
        rescue
          MatchError -> transform_tuple_literal(ast)
        end

      is_integer(ast) or is_boolean(ast) or is_binary(ast) or is_nil(ast) ->
        %{type: "Literal", value: ast}

      is_atom(ast) ->
        %{
          type: "CallExpression",
          callee: %{type: "Identifier", name: "Symbol"},
          arguments: [%{type: "Literal", value: ast}]
        }

      is_list(ast) ->
        %{
          type: "ArrayExpression",
          elements: transform_list!(ast)
        }

      true ->
        raise "Unknown AST #{ast}"
    end
  end

  def transform_list!(list) do
    list
    |> Enum.map(&transform!(&1))
    |> Enum.reject(&is_nil/1)
  end

  defp transform_non_literal({token, callee, args} = ast) do
    cond do
      token == :__aliases__ ->
        transform_module_reference(ast)

      token == :@ ->
        transform_module_attribute(ast)

      token == :for ->
        transform_comprehension(ast)

      token == :if ->
        transform_if(ast)

      token == :cond ->
        transform_cond(ast)

      token == :case ->
        transform_case(ast)

      token == :|> ->
        transform_pipeline(ast)

      token == :%{} ->
        transform_map(ast)

      token == := ->
        transform_assignment(ast)

      token == :not || token == :! ->
        transform_not_operator(ast)

      token in [:+, :*, :/, :-, :==, :<>, :and, :or, :||, :&&, :!=, :>] ->
        transform_binary_expression(ast)

      token == :++ ->
        transform_array_concat_operator(ast)

      token == :<<>> ->
        transform_string_interpolation(ast)

      token == :fn ->
        transform_anonymous_function(ast)

      token == :__block__ ->
        transform_block_statement(ast)

      token == :defmodule ->
        transform_module(ast)

      token == :{} ->
        transform_tuple_literal(ast)

      args == nil ->
        %{type: "Identifier", name: token}

      token == :& ->
        transform_function_capturing(ast)

      callee[:import] == Kernel or
          (Kernel.__info__(:functions) ++ Kernel.__info__(:macros))
          |> Keyword.keys()
          |> Enum.member?(token) ->
        transform_kernel_function(ast)

      is_list(args) ->
        transform_local_function(ast)

      true ->
        raise "Unknown token #{token}"
    end
  end

  defp transform_block_statement({_, _, args}) do
    body = with_block_state(fn -> transform_list!(args) end).body

    for line <- body do
      if Enum.member?(["ExpressionStatement", "VariableDeclaration"], line[:type]) do
        line
      else
        %{type: "ExpressionStatement", expression: line}
      end
    end
  end
end

defmodule ExScript.Common do
  @moduledoc """
  Helpers to generate common AST structures like IIEFs
  """

  alias ExScript.Compile, as: Compile

  def module_function_call(mod_name, fn_name, args) do
    ExScript.State.hoist_module_namespace(mod_name)

    if fn_name == :embed do
      [code] = args
      cmd = "echo \"#{code}\" | node_modules/.bin/acorn"
      js_ast = Poison.decode!(:os.cmd(String.to_charlist(cmd)))
      [first] = js_ast["body"]
      first
    else
      is_computed = fn_name |> Atom.to_string() |> String.contains?("?")

      %{
        type: "CallExpression",
        arguments: Compile.transform_list!(args),
        callee: %{
          type: "MemberExpression",
          object: %{
            type: "Identifier",
            name: mod_name
          },
          property:
            if is_computed do
              %{
                type: "Literal",
                value: fn_name,
                raw: fn_name
              }
            else
              %{
                type: "Identifier",
                name: fn_name
              }
            end,
          computed: is_computed
        }
      }
    end
  end

  def return_block(ast) do
    cond do
      is_tuple(ast) ->
        {key, _, body} = ast

        case key do
          :__block__ ->
            [return_line | fn_lines] = Enum.reverse(body)

            Enum.map(Enum.reverse(fn_lines), &Compile.transform!(&1)) ++
              dont_return_assignment(return_line)

          _ ->
            dont_return_assignment(ast)
        end

      true ->
        [%{type: "ReturnStatement", argument: Compile.transform!(ast)}]
    end
  end

  def iife(body) do
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

  def function_expression(type, args, return_val) do
    args = args || []

    %{
      type:
        case type do
          :arrow -> "ArrowFunctionExpression"
          :obj -> "FunctionExpression"
        end,
      params:
        Enum.map(args, fn ast ->
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
                elements:
                  Enum.map(els, fn {name, _, _} ->
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

  defp dont_return_assignment(ast) do
    {key, _, body} = ast

    if key == := do
      [{var_name, _, _}, _] = body

      [
        Compile.transform!(ast),
        %{
          type: "ReturnStatement",
          argument: %{type: "Identifier", name: var_name}
        }
      ]
    else
      [%{type: "ReturnStatement", argument: Compile.transform!(ast)}]
    end
  end
end

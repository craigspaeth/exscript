defmodule ExScript.Common do
  @moduledoc """
  Helpers to generate common AST structures like IIFEs
  """

  alias ExScript.Compile, as: Compile

  @cwd File.cwd!()

  def module_function_call(mod_name, fn_name, args) do
    ExScript.State.hoist_module_namespace(mod_name)

    if fn_name == :embed do
      [code] = args
      cmd = "echo \"#{code}\" | #{@cwd}/node_modules/.bin/acorn"
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

  def return_block(ast, fn_arg_var_names \\ []) do
    with_declared_vars(
      fn ->
        case ast do
          {key, _, body} ->
            case key do
              :__block__ ->
                [return_line | fn_lines] = Enum.reverse(body)

                body = Enum.map(Enum.reverse(fn_lines), &Compile.transform!(&1))
                ret = dont_return_assignment(return_line)
                body ++ ret

              _ ->
                dont_return_assignment(ast)
            end

          _ ->
            [%{type: "ReturnStatement", argument: Compile.transform!(ast)}]
        end
      end,
      fn_arg_var_names
    )
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

    params = Enum.map(args, &transform_arg/1)
    var_names = List.flatten(Enum.map(args, &var_name_from_arg/1))
    %{
      type:
        case type do
          :arrow -> "ArrowFunctionExpression"
          :obj -> "FunctionExpression"
        end,
      params: params,
      body: %{type: "BlockStatement", body: return_block(return_val, var_names)}
    }
  end

  defp var_name_from_arg(arg) do
    case arg do
      {_, _, [{key_name, {val_name, _, _}}]} ->
        key_name

      {left, right} ->
        [var_name_from_arg(left), var_name_from_arg(right)]

      {:{}, _, els} ->
        Enum.map(els, fn {name, _, _} -> name end)

      {var_name, _, _} ->
        var_name
    end
  end

  defp transform_arg(arg) do
    case arg do
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

      {left, right} ->
        %{
          type: "ArrayPattern",
          elements: [
            transform_arg(left),
            transform_arg(right)
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
  end

  def with_declared_vars(body_generator, ignore_names \\ []) do
    ExScript.State.start_block()
    body = body_generator.()

    var_names =
      ExScript.State.variables()
      |> Enum.reject(&Enum.member?(ignore_names, &1))

    declarations =
      Enum.map(var_names, fn var_name ->
        %{
          id: %{name: var_name, type: "Identifier"},
          type: "VariableDeclarator"
        }
      end)

    ExScript.State.end_block()

    if length(declarations) > 0 do
      variables = %{
        declarations: declarations,
        kind: "let",
        type: "VariableDeclaration"
      }

      [variables] ++ body
    else
      body
    end
  end

  defp dont_return_assignment(ast) do
    case ast do
      {key, _, body} when key == := ->
        [var, _] = body

        [
          Compile.transform!(ast),
          %{
            type: "ReturnStatement",
            argument: Compile.transform!(var)
          }
        ]

      _ ->
        [%{type: "ReturnStatement", argument: Compile.transform!(ast)}]
    end
  end
end

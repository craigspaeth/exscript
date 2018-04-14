defmodule ExScript.Common do
  @moduledoc """
  Helpers to generate common AST structures like IIFEs
  """

  alias ExScript.Compile, as: Compile

  @cwd File.cwd!()

  def module_function_call(mod_name, fn_name, args) when mod_name == "JS" and fn_name == :embed do
    ExScript.State.track_module_ref(mod_name)
    [code] = args
    if !is_bitstring(code), do: raise "Cant embed string interpolation"
    cmd = "echo \"#{code}\" | #{@cwd}/node_modules/.bin/acorn"
    js_ast = Poison.decode!(:os.cmd(String.to_charlist(cmd)))
    [first] = js_ast["body"]
    first
  end

  def module_function_call(mod_name, fn_name, args) do
    ExScript.State.track_module_ref(mod_name)
    %{
      type: "CallExpression",
      arguments: Compile.transform_list!(args),
      callee: callee(%{
        type: "Identifier",
        name: mod_name
      }, fn_name)
    }
  end

  def return_block(ast, fn_arg_var_names \\ []) do
    with_block_state(
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
    %{body: body, async: async} = return_block(return_val, var_names)

    %{
      async: async,
      type:
        case type do
          :arrow -> "ArrowFunctionExpression"
          :obj -> "FunctionExpression"
        end,
      params: params,
      body: %{type: "BlockStatement", body: body}
    }
  end


  def with_block_state(body_generator, ignore_names \\ []) do
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
    async = ExScript.State.block_async?

    ExScript.State.end_block()

    if length(declarations) > 0 do
      variables = %{
        declarations: declarations,
        kind: "let",
        type: "VariableDeclaration"
      }
      %{body: [variables] ++ body, async: async}
    else
      %{body: body, async: async}
    end
  end

  def is_punctuated(fn_name) do
    String.contains?(Atom.to_string(fn_name), "?") or
    String.contains?(Atom.to_string(fn_name), "!")
  end

  def callee(parent_ast, fn_name) do
    %{
      type: "MemberExpression",
      computed: is_punctuated(fn_name),
      object: parent_ast,
      property: if is_punctuated(fn_name) do
        %{
          raw: "\"#{fn_name}\"",
          type: "Literal",
          value: Atom.to_string(fn_name)
        }
      else
        %{
          type: "Identifier",
          name: fn_name
        }
      end
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

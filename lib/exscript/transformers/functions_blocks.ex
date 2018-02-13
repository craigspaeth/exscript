defmodule ExScript.Transformers.FunctionsBlocks do
  @moduledoc """
  Transforms function and block related Elixir ASTs to ESTree JSON
  """

  alias ExScript.Compile, as: Compile
  alias ExScript.Transformers.Modules, as: Modules


  def transform_kernel_function({fn_name, _, args}) do
    Modules.module_function_call "Kernel", fn_name, args
  end

  def transform_anonymous_function({_, _, args}) do
    fn_args = for {_, _, fn_args} <- args, do: fn_args
    [return_val | fn_args] = fn_args |> List.flatten |> Enum.reverse
    function_expression :arrow, Enum.reverse(fn_args), return_val
  end

  def transform_block_statement({_, _, args}) do
    %{
      type: "BlockStatement",
      body: Compile.transform_list! args
    }
  end

  def transform_external_function_call({
    {_, _, [{_, _, namespaces}, fn_name]}, _, args
  }) when not is_nil namespaces do
    mod_name = Enum.join namespaces, ""
    Modules.module_function_call mod_name, fn_name, args
  end

  def transform_external_function_call({
    {_, _, [{callee_name, _, namespaces}, fn_name]}, _, args
  }) when is_nil namespaces do
    %{
      type: "CallExpression",
      arguments: Enum.map(args, &Compile.transform!(&1)),
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
            Enum.map(Enum.reverse(fn_lines), &Compile.transform!(&1)) ++
            dont_return_assignment(return_line)
          _ ->
            dont_return_assignment ast
        end
      true ->
        [%{type: "ReturnStatement", argument: Compile.transform!(ast)}]
    end
  end

  def dont_return_assignment(ast) do
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
end

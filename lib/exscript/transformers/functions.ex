defmodule ExScript.Transformers.Functions do
  @moduledoc """
  Transforms function related Elixir ASTs to ESTree JSON
  """

  alias ExScript.Compile, as: Compile
  alias ExScript.Common, as: Common

  def transform_kernel_function({fn_name, _, args}) do
    Common.module_function_call("Kernel", fn_name, args)
  end

  def transform_anonymous_function({_, _, args}) do
    fn_args = for {_, _, fn_args} <- args, do: fn_args
    [return_val | fn_args] = fn_args |> List.flatten() |> Enum.reverse()
    Common.function_expression(:arrow, Enum.reverse(fn_args), return_val)
  end

  def transform_external_function_call({
        {_, _, [{_, _, namespaces}, fn_name]},
        _,
        args
      })
      when not is_nil(namespaces) do
    mod_name = Enum.join(namespaces, "")
    Common.module_function_call(mod_name, fn_name, args)
  end

  def transform_external_function_call({
        {_, _, [{callee_name, _, namespaces}, fn_name]},
        _,
        args
      })
      when is_nil(namespaces) do
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

  def transform_external_function_call({
        {_, _, [{callee_name, _, namespaces}, fn_name]},
        _,
        args
      })
      when is_nil(namespaces) do
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

  # An argument capture like &foo(&1, &2)
  def transform_function_capturing({_, _, [callee]}) when is_number(callee) do
    %{
      type: "Identifier",
      name: "arg#{callee}"
    }
  end

  # A reference to a module function like &foo/1
  def transform_function_capturing({_, _, [{:/, _, [{fn_name, _, _}, _]}]}) do
    %{
      type: "CallExpression",
      arguments: [%{type: "ThisExpression"}],
      callee: %{
        object: %{
          type: "MemberExpression",
          object: %{
            type: "ThisExpression"
          },
          property: %{
            type: "Identifier",
            name: fn_name
          }
        },
        property: %{name: "bind", type: "Identifier"},
        type: "MemberExpression"
      }
    }
  end

  # Shorthand function expression like &(1 + 1)
  def transform_function_capturing({_, _, [{{_, _, _}, _, _} = callee]}) do
    args = args_from_shortcuts(callee)

    if length(args) == 0 do
      transform_external_function_call(callee)[:callee]
    else
      Common.function_expression(:arrow, args, callee)
    end
  end

  # ???
  def transform_function_capturing({_, _, [callee]}) do
    Common.function_expression(:arrow, args_from_shortcuts(callee), callee)
  end

  defp args_from_shortcuts(callee) do
    {_, _, args} = callee

    if length(args) > 0 do
      total_args = count_shortcuts(args, 0)

      for i <- 1..total_args do
        {"arg#{i}", nil, nil}
      end
    else
      []
    end
  end

  defp count_shortcuts(args, count) do
    total =
      for {token, _, args} <- args do
        cond do
          token == :& and is_number(List.first(args)) ->
            1

          length(args) > 0 ->
            count_shortcuts(args, count)

          true ->
            0
        end
      end

    Enum.reduce(List.flatten(total), &(&1 + &2))
  end
end

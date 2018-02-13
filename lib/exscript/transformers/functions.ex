defmodule ExScript.Transformers.Functions do
  @moduledoc """
  Transforms function related Elixir ASTs to ESTree JSON
  """

  alias ExScript.Compile, as: Compile
  alias ExScript.Common, as: Common

  def transform_kernel_function({fn_name, _, args}) do
    Common.module_function_call "Kernel", fn_name, args
  end

  def transform_anonymous_function({_, _, args}) do
    fn_args = for {_, _, fn_args} <- args, do: fn_args
    [return_val | fn_args] = fn_args |> List.flatten |> Enum.reverse
    Common.function_expression :arrow, Enum.reverse(fn_args), return_val
  end

  def transform_external_function_call({
    {_, _, [{_, _, namespaces}, fn_name]}, _, args
  }) when not is_nil namespaces do
    mod_name = Enum.join namespaces, ""
    Common.module_function_call mod_name, fn_name, args
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
end

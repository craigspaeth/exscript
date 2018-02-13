defmodule ExScript.Transformers.ControlFlow do
  @moduledoc """
  Transforms control flow related Elixir ASTs to ESTree JSON
  """

  alias ExScript.Compile, as: Compile
  alias ExScript.Transformers.FunctionsBlocks, as: FunctionsBlocks

  def transform_if({_, _, [test, [{_, consequent}, {_, alternate}]]}) do
    expr = fn (body) ->
      if is_tuple(body) do
        FunctionsBlocks.iife(FunctionsBlocks.return_block(body))
      else
        Compile.transform!(body)
      end
    end
    %{
      type: "ConditionalExpression",
      test: Compile.transform!(test),
      consequent: expr.(consequent),
      alternate: expr.(alternate)
    }
  end

  def transform_cond({_, _, [[{_, clauses}]]}) do
    if_elses = for {_, _, [[condition], body]} <- clauses do
      [
        Compile.transform!(condition),
        %{
          type: "BlockStatement",
          body: FunctionsBlocks.return_block(body)
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

  def transform_case({_, _, [val, [{_, clauses}]]}) do
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
          left: Compile.transform!(val),
          right: Compile.transform!(compare_val)
        }),
        %{
          type: "BlockStatement",
          body: FunctionsBlocks.return_block(body)
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

  def nested_if_statement(if_elses, index \\ 0) do
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
end

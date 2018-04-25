defmodule ExScript.Transformers.Operators do
  @moduledoc """
  Transforms operator related Elixir ASTs to ESTree JSON
  """

  alias ExScript.Compile, as: Compile
  alias ExScript.Common, as: Common

  def transform_binary_expression({token, _, [left, right]}) do
    %{
      type: "BinaryExpression",
      operator:
        case token do
          :!= -> "!=="
          :== -> "==="
          :<> -> "+"
          :and -> "&&"
          :or -> "||"
          :not -> "!"
          _ -> token
        end,
      left: Compile.transform!(left),
      right: Compile.transform!(right)
    }
  end

  def transform_assignment({_, _, args}) do
    [vars, val] = args

    vars =
      if is_tuple(vars) and is_tuple(List.first(Tuple.to_list(vars))) do
        Tuple.to_list(vars)
      else
        vars
      end

    id =
      case vars do
        {:{}, _, vars} ->
          %{
            type: "ArrayPattern",
            elements:
              for {var_name, _, _} <- vars do
                ExScript.State.hoist_variable(var_name)
                %{type: "Identifier", name: var_name}
              end
          }

        vars when is_list(vars) ->
          {var_name, _, _} = Enum.at(vars, 0)

          %{
            type: "ArrayPattern",
            elements:
              if var_name == :| do
                {_, _, body} = Enum.at(vars, 0)
                [{head_var_name, _, _}, {tail_var_name, _, _}] = body

                ExScript.State.hoist_variable(head_var_name)
                ExScript.State.hoist_variable(tail_var_name)

                [
                  %{type: "Identifier", name: head_var_name},
                  %{
                    type: "RestElement",
                    argument: %{type: "Identifier", name: tail_var_name}
                  }
                ]
              else
                for {var_name, _, _} <- vars do
                  ExScript.State.hoist_variable(var_name)
                  %{type: "Identifier", name: var_name}
                end
              end
          }

        _ ->
          {var_name, _, _} = vars
          ExScript.State.hoist_variable(var_name)
          %{type: "Identifier", name: var_name}
      end

    %{
      type: "ExpressionStatement",
      expression: %{
        left: id,
        operator: "=",
        right: Compile.transform!(val),
        type: "AssignmentExpression"
      }
    }
  end

  def transform_not_operator({_, _, [val]}) do
    %{
      type: "UnaryExpression",
      operator: "!",
      argument: Compile.transform!(val)
    }
  end

  def transform_array_concat_operator({_, _, args}) do
    [left_arr, right_arr] = args

    %{
      type: "CallExpression",
      callee: %{
        type: "MemberExpression",
        property: %{type: "Identifer", name: "concat"},
        object: Compile.transform!(left_arr)
      },
      arguments: [Compile.transform!(right_arr)]
    }
  end

  def transform_pipeline({_, _, [arg | [fn_call]]} = ast) do
    fn_call_ast = Compile.transform!(fn_call)

    if fn_call_ast.type == "AwaitExpression" do
      %{
        type: "AwaitExpression",
        argument: Compile.transform!(arg)
      }
    else
      full_args_ast = [Compile.transform!(arg)] ++ fn_call_ast.arguments
      %{fn_call_ast | arguments: full_args_ast}
    end
  end

  def transform_string_interpolation({_, _, elements}) do
    els =
      List.flatten(
        for el <- elements do
          case el do
            {:::, _, _} ->
              {_, _, [{_, _, [interpolated_ast]}, _]} = el

              if el == List.last(elements) do
                template_el = %{
                  type: "TemplateElement",
                  value: %{
                    raw: "",
                    cooked: ""
                  },
                  tail: true
                }

                [
                  {:expression, Compile.transform!(interpolated_ast)},
                  {:quasis, template_el}
                ]
              else
                [{:expression, Compile.transform!(interpolated_ast)}]
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
        end
      )

    expressions = for {:expression, val} <- els, do: val
    quasis = for {:quasis, val} <- els, do: val

    %{
      type: "TemplateLiteral",
      expressions: expressions,
      quasis: quasis
    }
  end
end

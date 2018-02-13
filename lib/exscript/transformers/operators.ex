defmodule ExScript.Transformers.Operators do
  @moduledoc """
  Transforms operator related Elixir ASTs to ESTree JSON
  """

  alias ExScript.Compile, as: Compile
  alias ExScript.Transformers.Modules, as: Modules


  def transform_binary_expression({token, _, [left, right]}) do
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
      left: Compile.transform!(left),
      right: Compile.transform!(right)
    }
  end

  def transform_assignment({_, _, args}) do
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
          init: Compile.transform! val
        }
      ]
    }
  end

  def transform_not_operator({_, _, [val]}) do
    %{
      type: "UnaryExpression",
      operator: "!",
      argument: Compile.transform! val
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

  def transform_pipeline({_, _, [arg | [fn_call]]}) do
    {{_, _, [{_, _, [mod_name]}, fn_name]}, _, extra_args} = fn_call
    Modules.module_function_call(
      mod_name,
      fn_name,
      [arg | extra_args]
    )
  end

  def transform_string_interpolation({_, _, elements}) do
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
              {:expression, Compile.transform! interpolated_ast},
              {:quasis, template_el}
            ]
          else
            [{:expression, Compile.transform! interpolated_ast}]
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
end

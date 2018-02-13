defmodule ExScript.Compile do
  import ExScript.Common
  import ExScript.Transformers.Modules
  import ExScript.Transformers.Comprehensions
  import ExScript.Transformers.Functions
  import ExScript.Transformers.Operators
  import ExScript.Transformers.ControlFlow
  import ExScript.Transformers.Types

  @js_lib File.read!("lib/exscript/lib.js")
  @cwd File.cwd!()

  def compile!(code) do
    Code.compile_string(code)
    ast = Code.string_to_quoted!(code)
    @js_lib <> to_js!(ast)
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

    res =
      if is_tuple(ast) and Enum.at(Tuple.to_list(ast), 0) == :__block__ do
        {_, _, body} = ast

        body =
          Enum.map(body, fn ast ->
            %{type: "ExpressionStatement", expression: transform!(ast)}
          end)

        body = if is_nil(module_namespaces()), do: body, else: body ++ [module_namespaces()]
        %{type: "Program", body: body}
      else
        transform!(ast)
      end

    ExScript.State.clear()
    res
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

            token == :__aliases__ ->
              transform_module_reference(ast)

            token == :@ ->
              transform_module_attribute(ast)

            token == :for ->
              transform_comprehension(ast)

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

      token == :not ->
        transform_not_operator(ast)

      token in [:+, :*, :/, :-, :==, :<>, :and, :or, :||, :&&, :!=, :>] ->
        transform_binary_expression(ast)

      token == :++ ->
        transform_array_concat_operator(ast)

      token == :<<>> ->
        transform_string_interpolation(ast)

      callee[:import] == Kernel or
          Kernel.__info__(:functions)
          |> Keyword.keys()
          |> Enum.member?(token) ->
        transform_kernel_function(ast)

      token == :fn ->
        transform_anonymous_function(ast)

      token == :__block__ ->
        transform_block_statement(ast)

      token == :defmodule ->
        transform_module(ast)

      args == nil ->
        %{type: "Identifier", name: token}

      is_list(args) ->
        transform_local_function(ast)

      true ->
        raise "Unknown token #{token}"
    end
  end

  defp transform_block_statement({_, _, args}) do
    with_declared_vars(fn ->
      transform_list!(args)
    end)
  end
end

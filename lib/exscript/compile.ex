defmodule ExScript.Compile do
  import ExScript.Common
  import ExScript.Transformers.Modules
  import ExScript.Transformers.Comprehensions
  import ExScript.Transformers.Functions
  import ExScript.Transformers.Operators
  import ExScript.Transformers.ControlFlow
  import ExScript.Transformers.Types

  @cwd File.cwd!()

  def compile!(code) do
    app_code =
      code
      |> Code.string_to_quoted!()
      |> to_js!

    """
    (() => {
      #{runtime()};
      #{app_code};
      window.ExScript = ExScript;
    })()
    """
  end

  def runtime do
    stdlib = "#{@cwd}/lib/exscript/stdlib/*.ex"
    |> Path.wildcard()
    |> Enum.map(&File.read! &1)
    |> Enum.join()
    |> Code.string_to_quoted!()
    |> ExScript.Compile.to_js!()
    |> String.split("\n")
    |> Enum.drop(-1)
    |> Enum.join("\n")
    Enum.join([
      File.read!(@cwd <> "/lib/exscript/stdlib/pre.js"),
      stdlib,
      File.read!(@cwd <> "/lib/exscript/stdlib/post.js"),
      "const {#{Enum.join stdlib_module_names(), ", "}} = ExScript.Modules;"
    ])
  end

  def stdlib_module_names do
    "#{@cwd}/lib/exscript/stdlib/*.ex"
    |> Path.wildcard()
    |> Enum.map(
      &Path.basename(&1)
      |> String.split(".")
      |> List.first()
      |> (fn (s) -> if s in ["js", "io"], do: String.upcase(s), else: String.capitalize(s) end).()
    )
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

    body =
      if is_tuple(ast) and Enum.at(Tuple.to_list(ast), 0) == :__block__ do
        transform_block_statement(ast)
      else
        transform_block_statement({:__block__, [], [ast]})
      end

    body = if is_nil(module_namespaces()), do: body, else: body ++ [module_namespaces()]

    ExScript.State.clear()
    %{type: "Program", body: body}
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
      token == :__aliases__ ->
        transform_module_reference(ast)

      token == :@ ->
        transform_module_attribute(ast)

      token == :for ->
        transform_comprehension(ast)

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

      token == :& ->
        transform_function_capturing(ast)

      is_list(args) ->
        transform_local_function(ast)

      true ->
        raise "Unknown token #{token}"
    end
  end

  defp transform_block_statement({_, _, args}) do
    body = with_block_state(fn -> transform_list!(args) end).body

    for line <- body do
      if Enum.member?(["ExpressionStatement", "VariableDeclaration"], line[:type]) do
        line
      else
        %{type: "ExpressionStatement", expression: line}
      end
    end
  end
end

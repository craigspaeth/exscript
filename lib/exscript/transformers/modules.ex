defmodule ExScript.Transformers.Modules do
  @moduledoc """
  Transforms module (and module-related) Elixir ASTs to ESTree JSON
  """

  alias ExScript.Compile, as: Compile
  alias ExScript.Common, as: Common

  def transform_module({_, _, args}) do
    [{_, _, namespaces} | [body]] = args
    [{_, statement_or_statements} | _] = body
    {key, _, _} = statement_or_statements

    statements =
      if key == :__block__ do
        {_, _, methods} = statement_or_statements
        methods
      else
        [statement_or_statements]
      end

    namespace = Enum.join(namespaces, "")
    imports = for {:import, _, [{_, _, namespaces}]} <- statements do
      Enum.join(namespaces, "")
    end
    attributes = for {:@, _, [{var_name, _, [val]}]} <- statements, var_name != :moduledoc do
      {var_name, val}
    end
    methods = Enum.filter(statements, fn {key, _, _} -> key == :def or key == :defp end)

    imports_ast = for mod_name <- imports do
      ExScript.State.track_module_ref(mod_name)
      %{
        argument: %{
          name: mod_name,
          type: "Identifier"
        },
        type: "SpreadElement"
      }
    end
    attributes_ast = for {var_name, val} <- attributes do
      %{
        type: "Property",
        key: %{type: "Identifier", name: var_name},
        value: Compile.transform!(val)
      }
    end
    methods_ast = for method <- methods do
      {_, _, body} = method
      [{method_name, _, args}, [{_, return_val}]] = body
      method_name = if Common.is_punctuated(method_name) do
        "\"#{method_name}\""
      else
        method_name
      end
      %{
        type: "Property",
        method: true,
        key: %{type: "Identifier", name: method_name},
        value: Common.function_expression(:obj, args, return_val)
      }
    end
    ExScript.State.track_module_def(namespace)
    %{
      declarations: [
        %{
          id: %{
            name: namespace,
            type: "Identifier"
          },
          init: %{
            properties: imports_ast ++ attributes_ast ++ methods_ast,
            type: "ObjectExpression"
          },
          type: "VariableDeclarator"
        }
      ],
      kind: "const",
      type: "VariableDeclaration"
    }
  end

  def transform_module_reference({_, _, namespaces}) do
    mod_name = Enum.join(namespaces)
    ExScript.State.track_module_ref(mod_name)

    %{
      type: "Identifier",
      name: mod_name
    }
  end

  def transform_local_function({fn_name, _, [arg]}) when fn_name == :await  do
    ExScript.State.block_is_async()
    %{
      type: "AwaitExpression",
      argument: Compile.transform!(arg)
    }
  end

  def transform_local_function({fn_name, _, args}) when fn_name != :& do
    %{
      type: "CallExpression",
      arguments: Compile.transform_list!(args),
      callee: Common.callee(%{
        type: "ThisExpression"
      }, fn_name)
    }
  end

  def transform_module_attribute({_, _, [{attr_name, _, _}]}) do
    case attr_name do
      :moduledoc -> nil
      _ ->
        %{
          object: %{type: "ThisExpression"},
          property: %{name: attr_name, type: "Identifier"},
          type: "MemberExpression"
        }
    end
  end
end

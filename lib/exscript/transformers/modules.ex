defmodule ExScript.Transformers.Modules do
  @moduledoc """
  Transforms module (and module-related) Elixir ASTs to ESTree JSON
  """

  alias ExScript.Compile, as: Compile
  alias ExScript.Common, as: Common

  def transform_module({_, _, args}) do
    [{_, _, namespaces} | [body]] = args
    [{_, method_or_methods} | _] = body
    {key, _, _} = method_or_methods

    methods =
      if key == :__block__ do
        {_, _, methods} = method_or_methods
        methods
      else
        [method_or_methods]
      end

    methods = Enum.filter(methods, fn {key, _, _} -> key == :def or key == :defp end)
    namespace = Enum.join(namespaces, "")

    %{
      type: "AssignmentExpression",
      operator: "=",
      left: %{
        type: "MemberExpression",
        object: %{
          type: "MemberExpression",
          object: %{type:
           "Identifier", name: "ExScript"},
          property: %{type: "Identifier", name: "Modules"}
        },
        property: %{type: "Identifier", name: namespace}
      },
      right: %{
        type: "ObjectExpression",
        properties:
          for method <- methods do
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
              shorthand: false,
              computed: false,
              key: %{type: "Identifier", name: method_name},
              value: Common.function_expression(:obj, args, return_val)
            }
          end
      }
    }
  end

  def transform_module_reference({_, _, namespaces}) do
    mod_name = Enum.join(namespaces)
    ExScript.State.hoist_module_namespace(mod_name)

    %{
      type: "Identifier",
      name: mod_name
    }
  end

  def transform_module_attribute({_, _, [{attr_type, _, _}]}) do
    case attr_type do
      :moduledoc -> nil
    end
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

  def module_namespaces do
    mod_names = ExScript.State.module_namespaces()

    if length(mod_names) > 0 do
      %{
        declarations: [
          %{
            id: %{
              properties:
                for name <- mod_names do
                  %{
                    key: %{name: name, type: "Identifier"},
                    kind: "init",
                    shorthand: true,
                    type: "Property",
                    value: %{name: name, type: "Identifier"}
                  }
                end,
              type: "ObjectPattern"
            },
            init: %{
              object: %{name: "ExScript", type: "Identifier"},
              property: %{name: "Modules", type: "Identifier"},
              type: "MemberExpression"
            },
            type: "VariableDeclarator"
          }
        ],
        kind: "const",
        type: "VariableDeclaration"
      }
    else
      nil
    end
  end
end

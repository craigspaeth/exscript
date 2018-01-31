defmodule ExScript.Transformers.Modules do
  @moduledoc """
  Transforms module (and module-related) Elixir ASTs to ESTree JSON
  """
  
  alias ExScript.Compile, as: Compile

  def transform_module({_, _, args}) do
    [{_, _, namespaces} | [body]] = args
    [{_, method_or_methods} | _] = body
    {key, _, _} = method_or_methods
    methods = if key == :__block__ do
      {_, _, methods} = method_or_methods
      methods
    else
      [method_or_methods]
    end
    methods = Enum.filter methods, fn ({key, _, _}) -> key == :def end
    namespace = Enum.join namespaces, ""
    %{
      type: "AssignmentExpression",
      operator: "=",
      left: %{
        type: "MemberExpression",
        object: %{
          type: "MemberExpression",
          object: %{type: "Identifier", name: "ExScript"},
          property: %{type: "Identifier", name: "Modules"}
        },
        property: %{type: "Identifier", name: namespace}
      },
      right: %{
        type: "ObjectExpression",
        properties: for method <- methods do
          {_, _, body} = method
          [{method_name, _, args}, [{_, return_val}]] = body
          %{
            type: "Property",
            method: true,
            shorthand: false,
            computed: false,
            key: %{type: "Identifier", name: method_name},
            value: Compile.function_expression(:obj, args, return_val)
          }
        end
      }
    }
  end

  def transform_module_reference({_, _, [mod_name]}) do
    module_namespace mod_name
  end

  def transform_module_attribute({_, _, [{attr_type, _, _}]}= ast) do
    case attr_type do
      :moduledoc -> nil
    end
  end

  def transform_local_function({:&, _, [{_, _, [{fn_name, _, _}, _]}]}) do
    %{
      type: "MemberExpression",
      object: %{
        type: "ThisExpression",
      },
      property: %{
        type: "Identifier",
        name: fn_name
      }
    }
  end

  def transform_local_function({fn_name, _, args}) do
    %{
      type: "CallExpression",
      arguments: Compile.transform_list(args),
      callee: %{
        type: "MemberExpression",
        object: %{
          type: "ThisExpression",
        },
        property: %{
          type: "Identifier",
          name: fn_name
        }
      }
    }
  end

  def module_namespace(mod_name) do
    %{
      type: "MemberExpression",
      object: %{
        type: "MemberExpression",
        object: %{
          type: "Identifier",
          name: "ExScript"
        },
        property: %{
          type: "MemberExpression",
          name: "Modules"
        }
      },
      property: %{
        type: "MemberExpression",
        name: mod_name
      }
    }
  end

  def module_function_call(mod_name, fn_name, args) do
    if fn_name == :embed do
      [code] = args
      cmd = "echo \"#{code}\" | node_modules/.bin/acorn"
      js_ast = Poison.decode! :os.cmd String.to_charlist cmd
      [first] = js_ast["body"]
      first
    else
      is_computed = fn_name |> Atom.to_string() |> String.contains?("?")
      %{
        type: "CallExpression",
        arguments: Compile.transform_list(args),
        callee: %{
          type: "MemberExpression",
          object: module_namespace(mod_name),
          property: if is_computed do
            %{
              type: "Literal",
              value: fn_name,
              raw: fn_name
            }
          else
            %{
              type: "Identifier",
              name: fn_name
            }
          end,
          computed: is_computed
        }
      }
    end
  end
end
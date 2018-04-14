defmodule ExScript.Transformers.Types do
  @moduledoc """
  Transforms basic data type related Elixir ASTs to ESTree JSON
  """

  alias ExScript.Compile, as: Compile
  alias ExScript.Common, as: Common

  def transform_tuple_literal({:{}, _, var_names}) do
    %{
      type: "NewExpression",
      callee: %{
        type: "Identifier",
        name: "Tup"
      },
      arguments: Enum.map(var_names, &Compile.transform!(&1))
    }
  end

  def transform_tuple_literal(ast) do
    %{
      type: "NewExpression",
      callee: %{
        type: "Identifier",
        name: "Tup"
      },
      arguments:
        ast
        |> Tuple.to_list()
        |> Enum.map(&Compile.transform!(&1))
    }
  end

  def transform_map({_, _, args}) do
    %{
      type: "ObjectExpression",
      properties:
        for {key, val} <- args do
          if is_tuple(key) do
            {name, _, _} = key
            %{
              type: "Property",
              computed: true,
              key: %{type: "Identifier", name: name},
              value: Compile.transform!(val)
            }
          else
            %{
              type: "Property",
              key: %{type: "Identifier", name: key},
              value: Compile.transform!(val)
            }
          end
        end
    }
  end

  # ???
  def transform_property_access({
        {_, _, [_, action]},
        _,
        [owner, prop]
      } )
      when action == :get do
    %{
      type: "MemberExpression",
      computed: true,
      object: Compile.transform!(owner),
      property: Compile.transform!(prop)
    }
  end

  # Kernel function call e.g. is_map()
  def transform_property_access({
        {_, _, [Kernel, key]},
        _,
        args
      }) do
    %{
      type: "CallExpression",
      arguments: Compile.transform_list!(args),
      callee: %{
        type: "MemberExpression",
        object: %{type: "Identifier", name: "ExScript"},
        property: %{type: "Identifier", name: key}
      }
    }
  end

  # Property access e.g. map.foo
  def transform_property_access({
        {_, _, [parent_ast, key]},
        _,
        args
      })
      when length(args) == 0 do
    %{
      type: "MemberExpression",
      object: Compile.transform!(parent_ast),
      property: %{
        type: "Identifier",
        name: key
      }
    }
  end

  # Function property call e.g. map.foo("bar")
  def transform_property_access({
        {_, _, [parent_ast, key]},
        _,
        args
      }) do
    %{
      type: "CallExpression",
      arguments: Compile.transform_list!(args),
      callee: Common.callee(Compile.transform!(parent_ast), key)
    }
  end

  # ???
  def transform_property_access({
        {_, _, [{callee, _, _}]},
        _,
        args
      }) do
    %{
      type: "CallExpression",
      arguments: Compile.transform_list!(args),
      callee: %{
        type: "Identifier",
        name: callee
      }
    }
  end
end

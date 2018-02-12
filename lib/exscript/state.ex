defmodule ExScript.State do
  @moduledoc """
  Module that stores state through the lifecycle of the compiler like the module
  namespaces that need to be hoisted to the top of a program.
  """

  def init do
    Agent.start_link fn ->
      %{
        modules: []
      }
    end, name: __MODULE__
  end

  def hoist_module_namespace(mod_name) do
    Agent.update __MODULE__, fn state ->
      %{state | modules: state.modules ++ [mod_name]}
    end
  end

  def module_namespaces do
    Agent.get(__MODULE__, fn state -> state.modules end)
  end
end

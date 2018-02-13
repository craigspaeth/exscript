defmodule ExScript.State do
  @moduledoc """
  Module that stores state through the lifecycle of the compiler like the module
  namespaces that need to be hoisted to the top of a program.
  """

  @init_state %{
    modules: []
  }

  def init do
    Agent.start_link(
      fn -> @init_state end,
      name: __MODULE__
    )
  end

  def hoist_module_namespace(mod_name) do
    Agent.update(__MODULE__, fn state ->
      %{state | modules: Enum.uniq(state.modules ++ [mod_name])}
    end)
  end

  def module_namespaces do
    Agent.get(__MODULE__, fn state -> state.modules end)
  end

  def clear do
    Agent.update(__MODULE__, fn _ -> @init_state end)
  end
end

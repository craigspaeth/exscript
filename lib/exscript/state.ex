defmodule ExScript.State do
  @moduledoc """
  Module that stores state through the lifecycle of the compiler like the module
  namespaces that need to be hoisted to the top of a program.

  TODO: This feels like a hack. We can probably change the transformers to return
  metadata like -> {metadata, ast} to build up top-level things.
  """

  @init_state %{
    modules: [],
    variables: %{},
    current_block: UUID.uuid1()
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

  def new_block do
    Agent.update(__MODULE__, fn state ->
      %{state | current_block: UUID.uuid1()}
    end)
  end

  def hoist_variable(var_name) do
    Agent.update(__MODULE__, fn state ->
      cur_vars = state.variables[state.current_block] || []
      new_vars = Map.put(state.variables, state.current_block, Enum.uniq(cur_vars ++ [var_name]))
      %{state | variables: new_vars}
    end)
  end

  def variables do
    Agent.get(__MODULE__, fn state ->
      state.variables[state.current_block]
    end)
  end

  def clear do
    Agent.update(__MODULE__, fn _ -> @init_state end)
  end

  def clear_variables do
    Agent.update(__MODULE__, fn state ->
      %{state | variables: []}
    end)
  end
end

defmodule ExScript.State do
  @moduledoc """
  Module that stores state through the lifecycle of the compiler like the module
  namespaces that need to be hoisted to the top of a program.

  TODO: This feels like a hack. We can probably change the transformers to return
  metadata like -> {metadata, ast} to build up top-level things.
  """

  @init_state %{
    modules: [],
    variable_blocks: [[]]
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

  def start_block do
    Agent.update(__MODULE__, fn state ->
      %{state | variable_blocks: state.variable_blocks ++ [[]]}
    end)
  end

  def end_block do
    Agent.update(__MODULE__, fn state ->
      %{state | variable_blocks: Enum.drop(state.variable_blocks, -1)}
    end)
  end

  def hoist_variable(var_name) do
    Agent.update(__MODULE__, fn state ->
      new_vars = List.last(state.variable_blocks) ++ [var_name]
      new_blocks = List.replace_at(state.variable_blocks, -1, new_vars)
      %{state | variable_blocks: new_blocks}
    end)
  end

  def variables do
    Agent.get(__MODULE__, fn state ->
      Enum.uniq(List.last(state.variable_blocks))
    end)
  end

  def get do
    Agent.get(__MODULE__, fn state ->
      state
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

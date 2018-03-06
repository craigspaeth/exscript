defmodule ExScript.State do
  @moduledoc """
  Module that stores state through the lifecycle of the compiler like the module
  namespaces that need to be hoisted to the top of a program.

  TODO: This feels like a hack. We can probably change the transformers to return
  metadata like -> {metadata, ast} to build up top-level things.
  """

  @init_state %{
    module_refs: [],
    module_defs: [],
    variable_blocks: [[]],
    block_is_async: false,
  }
  def init do
    Agent.start_link(
      fn -> @init_state end,
      name: __MODULE__
    )
  end

  def track_module_ref(mod_name) do
    Agent.update(__MODULE__, fn state ->
      module_refs = (state.module_refs ++ [to_string(mod_name)])
      |> Enum.uniq()
      |> Enum.reject(&Enum.member? ExScript.Compile.stdlib_module_names, &1)
      %{state | module_refs: module_refs}
    end)
  end

  def track_module_def(mod_name) do
    Agent.update(__MODULE__, fn state ->
      module_defs = (state.module_defs ++ [to_string(mod_name)])
      |> Enum.uniq()
      |> Enum.reject(&Enum.member? ExScript.Compile.stdlib_module_names, &1)
      %{state | module_defs: module_defs}
    end)
  end

  def modules do
    Agent.get(__MODULE__, fn state ->
      Enum.uniq(state.module_refs ++ Enum.reverse(state.module_defs))
    end)
  end

  def module_defs do
    Agent.get(__MODULE__, fn state -> state.module_defs end)
  end

  def start_block do
    Agent.update(__MODULE__, fn state ->
      %{
        state
        | variable_blocks: state.variable_blocks ++ [[]],
        block_is_async: false
      }
    end)
  end

  def end_block do
    Agent.update(__MODULE__, fn state ->
      %{
        state |
        variable_blocks: Enum.drop(state.variable_blocks, -1)
      }
    end)
  end

  def hoist_variable(var_name) do
    Agent.update(__MODULE__, fn state ->
      new_vars = List.last(state.variable_blocks) ++ [var_name]
      new_blocks = List.replace_at(state.variable_blocks, -1, new_vars)
      %{state | variable_blocks: new_blocks}
    end)
  end

  def block_is_async do
    Agent.update(__MODULE__, fn state ->
      %{state | block_is_async: true}
    end)
  end

  def block_async? do
    Agent.get(__MODULE__, fn state ->
      state.block_is_async
    end)
  end

  def variables do
    Agent.get(__MODULE__, fn state ->
      state.variable_blocks
      |> List.last()
      |> Enum.uniq()
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

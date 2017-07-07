defmodule Mix.Tasks.Play do
  @moduledoc false

  use Mix.Task

  def run(_) do
    js = ExScript.Compile.compile! quote do: 1 + 2 * 4
    IO.inspect js
  end
end
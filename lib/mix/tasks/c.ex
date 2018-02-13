defmodule Mix.Tasks.C do
  @moduledoc """
  Convenient helper to compile a string of Elixir from stdin to JS
  """
  use Mix.Task

  def run(_) do
    stdin = String.trim(IO.read(:all))
    IO.puts(ExScript.Compile.to_js!(Code.string_to_quoted!(stdin)))
  end
end

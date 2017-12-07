defmodule Mix.Tasks.Example do
  @moduledoc false

  use Mix.Task

  def run(_) do
    File.write "example/app.js", ExScript.Compile.compile! File.read! "example/app.ex"
  end
end

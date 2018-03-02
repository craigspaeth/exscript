defmodule Mix.Tasks.Parse do
  @moduledoc """
  Parses Javascript code piped into stdin and outputs an Elixir map of the ESTree AST
  """

  use Mix.Task

  def run(_) do
    stdin = String.trim(IO.read(:all))
    acorn_code = "require('acorn').parse('#{stdin}', { ecmaVersion: 9 })"
    code = "process.stdout.write(JSON.stringify(#{acorn_code}))"
    {json, _} = System.cmd("node", ["-e", code])
    map = Poison.Parser.parse!(json, keys: :atoms)
    IO.inspect(List.first(remove_start_end(map)[:body]))
  end

  defp remove_start_end(map) do
    ignore_keys = [:end, :start, :method]

    for {k, v} <- map, not Enum.member?(ignore_keys, k), into: %{} do
      cond do
        is_map(v) ->
          {k, remove_start_end(v)}

        is_list(v) ->
          v =
            for item <- v do
              if is_map(item), do: remove_start_end(item), else: item
            end

          {k, v}

        true ->
          {k, v}
      end
    end
  end
end

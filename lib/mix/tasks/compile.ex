defmodule Mix.Tasks.Example do
  @moduledoc false

  use Mix.Task

  def run(_) do
    js = ExScript.Compile.compile! """
    defmodule Foo do
      defp to_html(view, model, el) do
        cond do
          is_bitstring el ->
            el
          is_list List.first(el) ->
            el
            |> Enum.map(fn (child) -> Foo.to_html view, model, child end)
            |> Enum.join("")
        end
      end
    end
    """
    File.write "./example.html", """
      <html>
        <head>
          <script>#{js}</script>
        </head>
      </html>
    """
  end
end

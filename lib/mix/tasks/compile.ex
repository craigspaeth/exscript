defmodule Mix.Tasks.Example do
  @moduledoc false

  use Mix.Task

  def run(_) do
    js = ExScript.Compile.compile! Code.string_to_quoted! """
    defmodule Foo do
      def foo(str) do
        a = case str do
          "a" -> "hi"
          "b" -> "bai"
          "c" -> "meh"
          _ -> fail
        end
        a <> " moo"
      end
    end
    Foo.foo("a")
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

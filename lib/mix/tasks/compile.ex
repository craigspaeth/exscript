defmodule Mix.Tasks.Example do
  @moduledoc false

  use Mix.Task

  def run(_) do
    js = ExScript.Compile.compile! Code.string_to_quoted! """
    defmodule Foo do
      def foo do
        "Foo"
      end
      def bar(str) do
        "Bar " <> str
      end
    end
    IO.inspect Foo.bar("baz")
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

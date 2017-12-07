defmodule Mix.Tasks.Example do
  @moduledoc false

  use Mix.Task

  def run(_) do
    js = ExScript.Compile.compile! """
    defmodule Foo do
      def foo do
        "foo"
      end
      def bar do
        "bar"
      end
      def either(str) do
        case str do
          "a" -> bar()
          "b" -> foo()
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

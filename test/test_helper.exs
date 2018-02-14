ExUnit.start()

defmodule ExScript.TestHelper do
  use ExUnit.Case

  def compare(ex, js_in) do
    js_out =
      ex
      |> Code.string_to_quoted!()
      |> ExScript.Compile.to_js!()

    assert js_out <> "\n" == js_in
  end
end

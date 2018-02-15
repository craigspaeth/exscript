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

  def compare_eval(ex_str) do
    {ex_res, _} = Code.eval_string(ex_str)

    stdlib =
      File.read!("lib/exscript/stdlib/enum.ex")
      |> Code.string_to_quoted!()
      |> ExScript.Compile.to_js!()

    stdlib =
      File.read!("lib/exscript/stdlib/pre.js") <>
        stdlib <> File.read!("lib/exscript/stdlib/post.js")

    js_code =
      "out = fn -> #{ex_str} end"
      |> Code.string_to_quoted!()
      |> ExScript.Compile.to_js!()

    code = "#{stdlib} #{js_code} process.stdout.write(JSON.stringify(out()))"
    {js_res, _} = System.cmd("node", ["-e", code])
    assert ex_res == Poison.decode!(js_res)
  end
end

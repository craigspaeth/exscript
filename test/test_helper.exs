ExUnit.start()

defmodule ExScript.TestHelper do
  use ExUnit.Case

  def compare(ex, js_in) do
    js_out =
      ex
      |> Code.string_to_quoted!()
      |> ExScript.Compile.to_js!()

    try do
      assert String.contains?(js_out <> "\n", js_in)
    rescue
      _ ->
        assert js_in == js_out
    end
  end

  def compare_eval(ex_str) do
    {ex_res, _} = Code.eval_string(ex_str)
    runtime = ExScript.Compile.runtime()

    js_code =
      "out = fn -> #{ex_str} end"
      |> Code.string_to_quoted!()
      |> ExScript.Compile.to_js!()

    code =
      "(async () => { #{runtime} #{js_code} process.stdout.write(JSON.stringify(await out())) })()"

    {json, _} = System.cmd("node", ["-e", code])
    # IO.puts(code)

    case Poison.Parser.parse(json, keys: :atoms) do
      {:ok, js_res} ->
        assert ex_res == js_res

      {:error, _} ->
        IO.puts(json)
        raise "Failure"
    end
  end
end

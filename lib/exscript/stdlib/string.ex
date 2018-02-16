defmodule ExScript.Stdlib.String do
  def split(string, pattern) do
    JS.embed("string.split(pattern)")
  end

  def to_atom(str) do
    JS.embed("Symbol(str)")
  end
end

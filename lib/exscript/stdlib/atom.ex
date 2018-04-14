defmodule ExScript.Stdlib.Atom do
  def to_string(atom) do
    JS.embed("JS.global().String(atom).slice(7, -1)")
  end
end

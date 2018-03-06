defmodule ExScript.Stdlib.String do
  def split(string, pattern) do
    JS.embed("string.split(pattern)")
  end

  def to_atom(str) do
    JS.embed("Symbol(str)")
  end

  def replace(subject, pattern, replacement) do
    JS.embed("subject.replace(pattern, replacement)")
  end

  def capitalize(str) do
    JS.embed "str.charAt(0).toUpperCase() + str.slice(1)"
  end
end

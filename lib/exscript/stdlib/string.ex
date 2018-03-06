defmodule ExScript.Stdlib.String do
  def split(_string, _pattern) do
    JS.embed("_string.split(_pattern)")
  end

  def to_atom(_str) do
    JS.embed("Symbol(_str)")
  end

  def replace(_subject, _pattern, _replacement) do
    JS.embed("_subject.replace(_pattern, _replacement)")
  end

  def capitalize(_str) do
    JS.embed "_str.charAt(0).toUpperCase() + _str.slice(1)"
  end
end

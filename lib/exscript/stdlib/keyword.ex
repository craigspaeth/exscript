defmodule ExScript.Stdlib.Keyword do

  def merge(keywords1, keywords2) do
    both = keywords1 ++ keywords2
    for {k, _} <- both do
      {k, Keyword.get(both, k)}
    end
  end

  def has_key?(keywords, key) do
    bools = for {k, _} <- keywords do
      Atom.to_string(k) == Atom.to_string(key)
    end
    Enum.member? bools, true
  end

  def get(keywords, key) do
    Enum.reduce Enum.reverse(keywords), fn ({k, v}, acc) ->
      if (Atom.to_string(k) == Atom.to_string(key)) do
        v
      else
        acc
      end
    end
  end

  def keyword?(keywords) do
    if keywords && length(keywords) > 0 do
      [first | _] = keywords
      if is_tuple(first) do
        {k, v} = first
        is_atom(k)
      else
        false
      end
    else
      false
    end
  end
end

defmodule ExScript.Stdlib.Kernel do

  def length(val) do
    JS.embed "val.length"
  end

  def is_tuple(val) do
    JS.embed "val instanceof Tup"
  end

  def is_atom(val) do
    JS.embed "typeof val === 'symbol'"
  end

  def is_bitstring(val) do
    JS.embed "typeof val === 'string'"
  end

  def is_list(val) do
    JS.embed "val instanceof Array"
  end
end
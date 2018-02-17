defmodule ExScript.Stdlib.Enum do
  def map(e, fun) do
    for i <- e do
      fun.(i)
    end
  end

  def reduce(enumerable, arg2, arg3) do
    JS.embed("const reducer = arg3 || arg2")
    JS.embed("const initVal = arg3 ? arg2 : enumerable[0]")
    JS.embed("const callback = (acc, val, i) => reducer(val, acc)")
    JS.embed("Array.prototype.reduce.call(enumerable, callback, initVal)")
  end

  def join(e, char) do
    JS.embed("Array.prototype.join.call(e, char)")
  end

  def at(e, index) do
    JS.embed("e[index]")
  end

  def member?(enumerable, element) do
    reduce enumerable, false, fn (i, acc) -> acc or i == element end
  end

  def with_index(enumerable) do
    JS.embed "let __i = 0"
    for i <- enumerable do
      JS.embed "__i++"
      index = JS.embed("__i - 1")
      {i, index}
    end
  end

  def reverse(enumerable) do
    JS.embed "enumerable.slice().reverse()"
  end
end

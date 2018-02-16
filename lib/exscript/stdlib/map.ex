defmodule ExScript.Stdlib.Map do
  def merge(map1, map2) do
    JS.embed("Object.assign({}, map1, map2)")
  end
end

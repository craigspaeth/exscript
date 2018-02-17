defmodule ExScript.Stdlib.Map do
  def merge(map1, map2) do
    JS.embed("Object.assign({}, map1, map2)")
  end

  def put(map, key, val) do
    k = Atom.to_string key
    JS.embed("Object.assign({}, map, { [k]: val })")
  end
end

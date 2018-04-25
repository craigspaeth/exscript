defmodule ExScript.Stdlib.List do
  def first(_list) do
    JS.embed("_list[0]")
  end

  def delete_at(_list, _index) do
    JS.embed("[..._list.slice(0, _index), ..._list.slice(_index + 1)]")
  end

  def replace_at(_list, _index, _val) do
    JS.embed("[..._list.slice(0, _index), _val, ..._list.slice(_index + 1)]")
  end
end

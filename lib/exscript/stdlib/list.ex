defmodule ExScript.Stdlib.List do

  def first(_list) do
    JS.embed "_list[0]"
  end
end

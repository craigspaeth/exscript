defmodule ExScript.Stdlib.IO do

  def puts(str) do
    JS.embed("console.log(str)")
  end

  def inspect(str) do
    JS.embed("console.debug(str)")
  end
end

defmodule ExScript.Stdlib.ExScript.Universal do
  def env?(atom), do: Atom.to_string(atom) == "browser"
end

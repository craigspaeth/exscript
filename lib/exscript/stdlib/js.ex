defmodule JS do
  @doc "No-op function that gets rewritten at compile-time to embed Javascript"
  def embed(_), do: nil
end

defmodule ExScript.Stdlib.JS do
  def root do
    JS.embed "typeof global !== 'undefined' && global || typeof window !== 'undefined' && window || {}"
  end
end

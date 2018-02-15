defmodule JS do
  @doc "No-op function that gets rewritten at compile-time to embed Javascript"
  def embed(_), do: nil
end

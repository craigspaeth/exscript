defmodule ExScript.Universal do
  @doc """
  Waits for a task or no-ops for non-tasks. Used as an isomorphic API that
  compiles to async/await in the browser.
  """
  def await(val) do
    if is_map(val) && Map.has_key?(val, :pid) && is_pid(val.pid) do
      Task.await(val)
    else
      val
    end
  end

  @doc """
  Returns an atom depending on which environment the code is running. One of
  [:browser, :server]
  """
  def env?(atom), do: atom == :server
end

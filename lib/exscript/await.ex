defmodule ExScript.Await do

  @doc """
  Waits for a task or no-ops for non-tasks. Used as an isomorphic API that
  compiles to async/await in the browser.
  """
  def await(val) do
    if is_map(val) && val.pid && is_pid(val.pid) do
      Task.await val
    else
      val
    end
  end
end

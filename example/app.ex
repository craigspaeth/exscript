defmodule App do
  def init do
    int = JS.window["setInterval"]
    int.(fn () ->
      render(%{ time: time() })
    end, 1000)
  end

  def time do
    moment = JS.window["moment"]
    moment.().format("MMMM Do YYYY, h:mm:ss a")
  end

  def render(props) do
    JS.window["ReactDOM"].render(
      JS.window["React"].createElement(fn (props) ->
        JS.window["React"].createElement("div", nil, "The time is ", props.time)
      end, props),
      JS.window["document"]["body"]
    )
  end
end
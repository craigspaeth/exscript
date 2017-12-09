defmodule App do
  def init do
    render_name "Harry"
  end

  def render_name(name) do
    ViewClient.render View, %{name: name}    
  end
end

defmodule ViewClient do
  def to_react_el(dsl_el) do
    [tag_label | children] = dsl_el
    attrs = if Keyword.keyword? List.first children do
      JS.embed "debugger"
      Enum.reduce List.first(children), fn ({k, v}, acc) ->
        IO.inspect k
        IO.inspect v
        IO.inspect acc
      end
    else
      nil
    end
    cond do
      length(children) == 1 and is_bitstring(List.first children) ->
        text_node attrs, dsl_el
      true ->
        Enum.map children, fn (el) -> to_react_el(el) end
    end
  end

  def text_node(attrs, dsl_el) do
    [tag_label, text] = dsl_el
    JS.window["React"].createElement(fn (props) ->
      JS.window["React"].createElement(Atom.to_string(tag_label), attrs, text)
    end, %{})
  end

  def render(view, model) do
    el = to_react_el view.render model
    JS.window["ReactDOM"].render el, JS.window["document"]["body"]    
  end
end

defmodule View do
  def render(model) do
    [:div,
      [:h2, "Welcome"],
      [:h1, "Hello #{model.name}"],
      [:a, [href: "google.com"], "See Google"]]
  end
end
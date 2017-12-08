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
    cond do
      length(children) == 1 and is_bitstring(List.first children) ->
        text_node dsl_el
      is_list List.first children ->
        Enum.map children, fn (el) -> to_react_el(el) end
    end
  end

  def text_node(dsl_el) do
    [tag_label, text] = dsl_el
    JS.window["React"].createElement(fn (props) ->
      JS.window["React"].createElement(Atom.to_string(tag_label), nil, text)
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
      [:h1, "Hello #{model.name}"]]
  end
end
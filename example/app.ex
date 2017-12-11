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
      Enum.reduce List.first(children), %{}, fn ({k, v}, acc) ->
        Map.put acc, Atom.to_string(k), v
      end
    else
      nil
    end
    [_ | childs] = if attrs != nil, do: children, else: [nil] ++ children
    cond do
      is_bitstring(List.first childs) ->
        text_node tag_label, attrs, List.first childs
      true ->
        Enum.map childs, fn (el) -> to_react_el(el) end
    end
  end

  def text_node(tag_label, attrs, text) do
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
  def onclick(e) do
    IO.inspect e
  end

  def render(model) do
    [:div,
      [:h2, "Welcome"],
      [:h1, "Hello #{model.name}"],
      [:ul,
        [:li, "a"],
        [:li, "b"],
        [:a, [href: "hi"], [:p, "a"], [:p, "Hello World"]],
        [:button, [onClick: &onclick/1], "Hello World"]]]
  end
end
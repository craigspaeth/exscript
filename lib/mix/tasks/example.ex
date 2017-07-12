defmodule Mix.Tasks.Example do
  @moduledoc false

  use Mix.Task

  def run(_) do
    js = ExScript.Compile.compile! """
    defmodule Griffin.View.Server do
      def render(view, model) do
        to_html view, model, view.render model
      end

      defp to_html(view, model, el) do
        cond do
          is_bitstring el ->
            el
          is_list List.first(el) ->
            el
            |> Enum.map(fn (child) -> to_html view, model, child end)
            |> Enum.join("")
          is_list el ->
            [tag_label | children] = el
            has_els_func = not is_nil view.__info__(:functions)[:els]
            if has_els_func and not is_nil view.els[tag_label] do
              IO.inspect view.els[tag_label]
              # to_html view, model, view.els[tag_label].render model
            else
              {open, close} = split_tag_label view, tag_label
              children = children
              |> Enum.map(fn (child) -> to_html view, model, child end)
              |> Enum.join("")
            end
        end
      end

      defp split_tag_label(view, tag) do
      end
    end
    """
    File.write "./example.html", """
      <html>
        <head>
          <script>#{js}</script>
        </head>
      </html>
    """
  end
end

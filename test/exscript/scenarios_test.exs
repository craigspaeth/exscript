defmodule ExScript.Compile.ScenariosTest do
  use ExUnit.Case

  test "compiles griffin style function" do
    ExScript.TestHelper.compare(
      """
      defmodule Griffin.View.Client do
        defp inline_styles(view, tag_label) do
          [_ | refs] = tag_label |> Kernel.to_string() |> String.split("@")
          if length(refs) > 0 do
            refs
            |> Enum.map(&view.styles[String.to_atom &1])
            |> Enum.reduce(fn (style_map, acc) -> Keyword.merge acc, style_map end)
            |> Enum.reverse
            |> Enum.map(fn ({k, v}) ->
                k = String.replace to_string(k), "_", "-"
                {k, v}
              end)
            |> Enum.into %{}
          else
            nil
          end
        end
      end
      """,
      """
      ExScript.Modules.GriffinViewClient = {
          inline_styles(view, tag_label) {
              let _, refs;
              [_, ...refs] = String.split(Kernel.to_string(tag_label), '@');
              return Kernel.length(refs) > 0 ? (() => {
                  return Enum.into(Enum.map(Enum.reverse(Enum.reduce(Enum.map(refs, arg1 => {
                      return view.styles[String.to_atom(arg1)];
                  }), (style_map, acc) => {
                      return Keyword.merge(acc, style_map);
                  })), ([k, v]) => {
                      k = String.replace(this.to_string(k), '_', '-');
                      return new Tuple(k, v);
                  }), {});
              })() : null;
          }
      };
      const {String, Kernel, Enum, Keyword} = ExScript.Modules;
      """
    )
  end
end

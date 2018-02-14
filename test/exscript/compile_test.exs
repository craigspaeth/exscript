defmodule ExScript.Compile.CompileTest do
  use ExUnit.Case

  test "surfaces elixir compile errors" do
    try do
      ExScript.Compile.compile!("""
        defmoo Foo do
        end
      """)
    rescue
      err ->
        assert err == %CompileError{
                 description: "undefined function defmoo/2",
                 file: "nofile",
                 line: 1
               }
    end
  end

  test "compiles embedded code" do
    ast =
      Code.string_to_quoted!("""
      fn () ->
        a = "a"
        JS.embed "debugger"
        b = "b"
      end
      """)

    js = ExScript.Compile.to_js!(ast)

    assert js <> "\n" == """
           () => {
               let a, b;
               a = 'a';
               debugger;
               b = 'b';
               return b;
           };
           const {JS} = ExScript.Modules;
           """
  end
end

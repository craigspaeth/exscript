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
    ExScript.TestHelper.compare(
      """
      fn () ->
        a = "a"
        JS.embed "debugger"
        b = "b"
      end
      """,
      """
      () => {
          let a, b;
          a = 'a';
          debugger;
          b = 'b';
          return b;
      };
      """
    )
  end

  @tag :skip
  test "compiles multiline embedded code" do
    ExScript.TestHelper.compare(
      """
      JS.embed(\"\"\"
      class Foo extends Bar {
        constructor() {
          return 'hi';
        }
      }
      \"\"\")
      """,
      """
      class Foo extends Bar {
        constructor() {
          return 'hi';
        }
      }
      """
    )
  end
end

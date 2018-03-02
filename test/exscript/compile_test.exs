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

  test "compiles await calls into async/await functions" do
    ExScript.TestHelper.compare(
      """
      fn () ->
        res = await fetch()
      end
      """,
      """
      async () => {
          let res;
          res = await this.fetch();
          return res;
      };
      """
    )
  end

  test "compiles imports into mixins" do
    ExScript.TestHelper.compare(
      """
      defmodule Foo do
        import Bar
        def foo, do: 1
      end
      """,
      """
      ExScript.Modules.Foo = {
          ...ExScript.Modules.Bar,
          foo() {
              return 1;
          }
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

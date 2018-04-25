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

  test "compiles embeds into module attrs" do
    ExScript.TestHelper.compare(
      """
      defmodule Foo do
        @bar JS.embed("baz()")
      end
      """,
      """
      const Foo = { bar: baz() };
      """
    )
  end

  test "warns against dynamic embedded code" do
    err =
      try do
        ExScript.Compile.to_js!(
          Code.string_to_quoted!("""
            JS.embed("debugger \#{a}")
          """)
        )
      rescue
        str -> str
      end

    assert err.message == "Cant embed string interpolation"
  end

  test "warns against invalid embedded code" do
    err =
      try do
        ExScript.Compile.to_js!(
          Code.string_to_quoted!("""
            JS.embed("foo {")
          """)
        )
      rescue
        str -> str
      end

    assert err.message == "Invalid embedded JS"
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
      const Foo = {
          ...Bar,
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

defmodule ExScript.Compiler.FunctionsTest do
  use ExUnit.Case

  test "compiles anonymous functions" do
    ExScript.TestHelper.compare(
      """
      fn a, b -> "hi" end
      """,
      """
      (a, b) => {
          return 'hi';
      };
      """
    )
  end

  test "compiles multiline functions" do
    ExScript.TestHelper.compare(
      """
      fn ->
        a = 1
        b = 2
        a + b
      end
      """,
      """
      () => {
          let a, b;
          a = 1;
          b = 2;
          return a + b;
      };
      """
    )
  end

  test "compiles kernel functions" do
    js = ExScript.Compile.to_js!(quote do: is_boolean(true))
    assert js == "Kernel.is_boolean(true);\nconst {Kernel} = ExScript.Modules;"
    js = ExScript.Compile.to_js!(quote do: is_list(true))
    assert js == "Kernel.is_list(true);\nconst {Kernel} = ExScript.Modules;"
    js = ExScript.Compile.to_js!(quote do: is_nil(true))
    assert js == "Kernel.is_nil(true);\nconst {Kernel} = ExScript.Modules;"
    js = ExScript.Compile.to_js!(quote do: length("a"))
    assert js == "Kernel.length('a');\nconst {Kernel} = ExScript.Modules;"
  end

  test "compiles kernel functions in function body" do
    ExScript.TestHelper.compare(
      """
      fn ->
        a = 1
        length a
      end
      """,
      """
      () => {
          let a;
          a = 1;
          return Kernel.length(a);
      };
      const {Kernel} = ExScript.Modules;
      """
    )
  end

  test "compiles lexically anonymous function calls" do
    ExScript.TestHelper.compare(
      """
      a = fn () -> "foo" end
      a.()
      """,
      """
      let a;
      a = () => {
          return 'foo';
      };
      a();
      """
    )
  end

  test "compiles blocks that return assignment" do
    ExScript.TestHelper.compare(
      """
      a = if true do
        c = "a"
        a = "c"
      else
        "b"
      end
      """,
      """
      let a;
      a = true ? (() => {
          let c, a;
          c = 'a';
          a = 'c';
          return a;
      })() : 'b';
      """
    )
  end

  test "compiles map pattern matching in function arguments" do
    ExScript.TestHelper.compare(
      """
      fn (%{a: b}) ->
        a
      end
      """,
      """
      ({a: b}) => {
          return a;
      };
      """
    )
  end

  test "compiles tuple pattern matching in function arguments" do
    ExScript.TestHelper.compare(
      """
      fn ({a, b, c}) ->
        a
      end
      """,
      """
      ([a, b, c]) => {
          return a;
      };
      """
    )
  end

  test "compiles double tuple pattern matching in function arguments" do
    ExScript.TestHelper.compare(
      """
      fn ({a, b}) ->
        a
      end
      """,
      """
      ([a, b]) => {
          return a;
      };
      """
    )
  end

  test "compiles ? functions smartly" do
    ExScript.TestHelper.compare(
      """
      Keyword.keyword?("a")
      """,
      """
      Keyword['keyword?']('a');
      const {Keyword} = ExScript.Modules;
      """
    )
  end

  test "compiles functions in keyword lists" do
    ExScript.TestHelper.compare(
      """
      a = [foo: fn -> "bar" end]
      """,
      """
      let a;
      a = [new ExScript.Types.Tuple(Symbol('foo'), () => {
              return 'bar';
          })];
      """
    )
  end

  test "declares let variables at the top of a block for reassignment" do
    ExScript.TestHelper.compare(
      """
      defmodule Foo do
        def a do
          b = "bar"
          c = fn ->
            d = "qux"
            e = fn ->
              f = "moo"
            end
          end
          b = "baz"
        end
        def b do
          x = "foo"
        end
      end
      """,
      """
      ExScript.Modules.Foo = {
          a() {
              let b, c;
              b = 'bar';
              c = () => {
                  let d, e;
                  d = 'qux';
                  e = () => {
                      let f;
                      f = 'moo';
                      return f;
                  };
                  return e;
              };
              b = 'baz';
              return b;
          },
          b() {
              let x;
              x = 'foo';
              return x;
          }
      };
      """
    )
  end

  test "compiles anonymous functions with multiple arguments" do
    ExScript.TestHelper.compare(
      """
      Enum.reduce [1,2,3], fn (i, acc) -> i + acc end
      """,
      """
      Enum.reduce([
          1,
          2,
          3
      ], (i, acc) => {
          return i + acc;
      });
      const {Enum} = ExScript.Modules;
      """
    )
  end
end

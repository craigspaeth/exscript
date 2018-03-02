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
    assert js == "Kernel.is_boolean(true);"
    js = ExScript.Compile.to_js!(quote do: is_list(true))
    assert js == "Kernel.is_list(true);"
    js = ExScript.Compile.to_js!(quote do: is_nil(true))
    assert js == "Kernel.is_nil(true);"
    js = ExScript.Compile.to_js!(quote do: length("a"))
    assert js == "Kernel.length('a');"
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

  test "compiles punctuated function calls on a property" do
    ExScript.TestHelper.compare(
      """
      a.foo!("bar")
      """,
      """
      a['foo!']('bar');
      """
    )
  end

  @tag :skip
  test "compiles function calls on a property" do
    ExScript.TestHelper.compare(
      """
      a = %{foo: fn () -> "foo" end}
      a.foo
      """,
      """
      let a;
      a = {
          foo: () => {
              return 'foo';
          }
      };
      a.foo();
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

  test "compiles functions in keyword lists" do
    ExScript.TestHelper.compare(
      """
      a = [foo: fn -> "bar" end]
      """,
      """
      let a;
      a = [new Tup(Symbol('foo'), () => {
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
      """
    )
  end

  test "compiles function capturing" do
    ExScript.TestHelper.compare(
      """
      IO.puts(&IO.puts)
      """,
      """
      IO.puts(IO.puts);
      """
    )
  end

  test "compiles simple function capture shortcuts" do
    ExScript.TestHelper.compare(
      """
      fun = &(&1 + 1 + &2)
      """,
      """
      let fun;
      fun = (arg1, arg2) => {
          return arg1 + 1 + arg2;
      };
      """
    )
  end

  test "compiles function capture shortcuts" do
    ExScript.TestHelper.compare(
      """
      defmodule Foo do
        def foo(i), do: i + 1
      end
      Enum.map [1,2,3], &Foo.foo &1
      """,
      """
      ExScript.Modules.Foo = {
          foo(i) {
              return i + 1;
          }
      };
      Enum.map([
          1,
          2,
          3
      ], arg1 => {
          return Foo.foo(arg1);
      });
      const {Foo} = ExScript.Modules;
      """
    )
  end

  test "compiles pattern tuples inside anonymous function bodies" do
    ExScript.TestHelper.compare(
      """
      Enum.map(fn ({k, v}) ->
        k = String.replace "ab", "b"
        {k, v}
      end)
      """,
      """
      Enum.map(([k, v]) => {
          k = String.replace('ab', 'b');
          return new Tup(k, v);
      });
      """
    )
  end

  test "compiles nested functions with reassignment" do
    ExScript.TestHelper.compare(
      """
      fn (a) ->
        a = fn (b) ->
          b = "a"
        end
      end
      """,
      """
      a => {
          a = b => {
              b = 'a';
              return b;
          };
          return a;
      };
      """
    )
  end

  test "compiles pattern matching in returns" do
    ExScript.TestHelper.compare(
      """
      fn ->
        {k, v} = {"a", "b"}
      end
      """,
      """
      () => {
          let k, v;
          [k, v] = new Tup('a', 'b');
          return new Tup(k, v);
      };
      """
    )
  end
end

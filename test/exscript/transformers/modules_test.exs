defmodule ExScript.Compiler.ModulesTest do
  use ExUnit.Case

  test "compiles modules" do
    ExScript.TestHelper.compare(
      """
      defmodule Hello.World do
        def hi, do: "hi"
        def bai, do: 1 + 1
      end
      """,
      """
      ExScript.Modules.HelloWorld = {
          hi() {
              return 'hi';
          },
          bai() {
              return 1 + 1;
          }
      };
      """
    )
  end

  test "compiles module function args in the right order" do
    ExScript.TestHelper.compare(
      """
      defmodule Hello.World do
        def hi(a, b) do
          a
        end
      end
      """,
      """
      ExScript.Modules.HelloWorld = {
          hi(a, b) {
              return a;
          }
      };
      """
    )
  end

  test "compiles multiline module functions" do
    ExScript.TestHelper.compare(
      """
      defmodule Hello.World do
        def hi do
          a = 1
          a
        end
      end
      """,
      """
      ExScript.Modules.HelloWorld = {
          hi() {
              let a;
              a = 1;
              return a;
          }
      };
      """
    )
  end

  test "compiles private module functions" do
    ExScript.TestHelper.compare(
      """
      defmodule Hello.World do
        defp hi do
          a = 1
          a
        end
      end
      """,
      """
      ExScript.Modules.HelloWorld = {
          hi() {
              let a;
              a = 1;
              return a;
          }
      };
      """
    )
  end

  test "compiles basic function calls" do
    ExScript.TestHelper.compare(
      """
      IO.puts("a")
      """,
      """
      IO.puts('a');
      """
    )
  end

  test "compiles function calls with anonymous functions as args" do
    ExScript.TestHelper.compare(
      """
      Enum.map [1,2,3], fn (i) -> i + 1 end
      """,
      """
      Enum.map([
          1,
          2,
          3
      ], i => {
          return i + 1;
      });
      """
    )
  end

  test "compiles external module function calls" do
    ExScript.TestHelper.compare(
      """
      defmodule Hello do
        def world(str), do: "World" <> str
      end
      defmodule Main do
        def init do
          Hello.world("Earth")
        end
      end
      """,
      """
      ExScript.Modules.Hello = {
          world(str) {
              return 'World' + str;
          }
      };
      ExScript.Modules.Main = {
          init() {
              return Hello.world('Earth');
          }
      };
      const {Hello} = ExScript.Modules;
      """
    )
  end

  test "compiles property function calls" do
    ExScript.TestHelper.compare(
      """
      defmodule Hello do
        def world(mod) do
          mod.fun("a")
        end
      end
      """,
      """
      ExScript.Modules.Hello = {
          world(mod) {
              return mod.fun('a');
          }
      };
      """
    )
  end

  test "compiles dynamic property access" do
    ExScript.TestHelper.compare(
      """
      fn () ->
        foo = %{foo: "bar"}
        key = "bar"
        foo[key]
      end
      """,
      """
      () => {
          let foo, key;
          foo = { foo: 'bar' };
          key = 'bar';
          return foo[key];
      };
      """
    )
  end

  test "compiles dynamic property access with function calls" do
    ExScript.TestHelper.compare(
      """
      defmodule Hello do
        def bar, do: "prop"
        def foo(a) do
          a.foo[bar()].baz "bam"
        end
      end
      """,
      """
      ExScript.Modules.Hello = {
          bar() {
              return 'prop';
          },
          foo(a) {
              return a.foo[this.bar()].baz('bam');
          }
      };
      """
    )
  end

  test "compiles local module functions" do
    ExScript.TestHelper.compare(
      """
      defmodule Hello.World do
        def hi, do: bai()
        def bai, do: "bai"
      end
      """,
      """
      ExScript.Modules.HelloWorld = {
          hi() {
              return this.bai();
          },
          bai() {
              return 'bai';
          }
      };
      """
    )
  end

  test "compiles ? module functions" do
    ExScript.TestHelper.compare(
      """
      defmodule Hello.World do
        def hi, do: bai?()
      end
      """,
      """
      ExScript.Modules.HelloWorld = {
          hi() {
              return this['bai?']();
          }
      };
      """
    )
  end

  test "compiles local module function references" do
    ExScript.TestHelper.compare(
      """
      defmodule Hello.World do
        def hi, do: [:a, &bai/1]
        def bai, do: "bai"
      end
      """,
      """
      ExScript.Modules.HelloWorld = {
          hi() {
              return [
                  Symbol('a'),
                  this.bai
              ];
          },
          bai() {
              return 'bai';
          }
      };
      """
    )
  end

  test "compiles references to module functions" do
    ExScript.TestHelper.compare(
      """
      IO.puts IO
      """,
      """
      IO.puts(IO);
      """
    )
  end

  test "compiles moduledocs" do
    ExScript.TestHelper.compare(
      """
      defmodule Hi do
        @moduledoc "hi"
        def bai, do: "bai"
      end
      """,
      """
      ExScript.Modules.Hi = {
          bai() {
              return 'bai';
          }
      };
      """
    )
  end

  test "compiles nested module references" do
    ExScript.TestHelper.compare(
      """
      defmodule Hello.Earth do
        def hi, do: "hi"
      end
      defmodule Hello.Mars do
        def hi, do: Hello.Earth.hi()
      end
      """,
      """
      ExScript.Modules.HelloEarth = {
          hi() {
              return 'hi';
          }
      };
      ExScript.Modules.HelloMars = {
          hi() {
              return HelloEarth.hi();
          }
      };
      const {HelloEarth} = ExScript.Modules;
      """
    )
  end

  test "hoists the namepsace for readability" do
    ExScript.TestHelper.compare(
      """
      IO.puts "foo"
      JS.log "bar"
      """,
      """
      IO.puts('foo');
      JS.log('bar');
      """
    )
  end

  test "hoists no duplicates" do
    ExScript.TestHelper.compare(
      """
      JS.log "bar"
      a = fn ->
        JS.foo "baz"
      end
      """,
      """
      let a;
      JS.log('bar');
      a = () => {
          return JS.foo('baz');
      };
      """
    )
  end

  test "compiles references to modules" do
    ExScript.TestHelper.compare(
      """
      IO.puts IO
      """,
      """
      IO.puts(IO);
      """
    )
  end

  test "compiles ? methods" do
    ExScript.TestHelper.compare(
      """
      defmodule Foo do
        def foo?, do: "foo"
      end
      """,
      """
      ExScript.Modules.Foo = {
          "foo?"() {
              return 'foo';
          }
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
      """
    )
  end

  test "compiles ! functions smartly" do
    ExScript.TestHelper.compare(
      """
      Foo.bar!("a")
      """,
      """
      Foo['bar!']('a');
      const {Foo} = ExScript.Modules;
      """
    )
  end
end

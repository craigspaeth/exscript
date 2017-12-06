defmodule ExScript.CompileTest do
  @moduledoc false

  use ExUnit.Case

  test "surfaces elixir compile errors" do
    try do
      ExScript.Compile.compile! """
        defmoo Foo do
        end
      """
    rescue
      err -> assert err == %CompileError{
        description: "undefined function defmoo/2",
        file: "nofile",
        line: 1
      }
    end
  end

  test "compiles basic arithmetic" do
    js = ExScript.Compile.to_js! quote do: 1 + 2 * 3 / 4 - 5
    assert js == "1 + 2 * 3 / 4 - 5"
  end

  test "compiles identitfying functions" do
    js = ExScript.Compile.to_js! quote do: is_boolean(true)
    assert js == "ExScript.is_boolean(true)"
    js = ExScript.Compile.to_js! quote do: is_array(true)
    assert js == "ExScript.is_array(true)"
  end

  test "compiles assignment" do
    js = ExScript.Compile.to_js! quote do: a = 1
    assert js == "const a = 1;"
  end

  test "compiles equality" do
    js = ExScript.Compile.to_js! quote do: true == false
    assert js == "true === false"
  end

  test "compiles atoms" do
    js = ExScript.Compile.to_js! quote do: :hello
    assert js == "Symbol('hello');"
  end

  test "compiles strings" do
    js = ExScript.Compile.to_js! quote do: "Hello"
    assert js == "'Hello'"
  end

  test "compiles anonymous functions" do
    js = ExScript.Compile.to_js! quote do: fn (a, b) -> "hi" end
    assert js <> "\n" == """
    (b, a) => {
        return 'hi';
    }
    """
  end

  test "compiles multiline functions" do
    js = ExScript.Compile.to_js! Code.string_to_quoted! """
      fn ->
        a = 1
        a
      end
    """
    assert js <> "\n" == """
    () => {
        const a = 1;
        return a;
    }
    """
  end

  test "compiles lists" do
    js = ExScript.Compile.to_js! quote do: [1, 2, 3]
    assert js <> "\n" == """
    [
        1,
        2,
        3
    ]
    """
  end

  test "compiles maps" do
    js = ExScript.Compile.to_js! quote do: %{foo: "bar", baz: "qux"}
    assert js <> "\n" == """
    {
        foo: 'bar',
        baz: 'qux'
    }
    """
  end

  test "compiles nil" do
    js = ExScript.Compile.to_js! quote do: nil
    assert js == "null"
  end

  test "compiles modules" do
    ast = Code.string_to_quoted! """
    defmodule Hello.World do
      def hi, do: "hi"
      def bai, do: 1 + 1
    end
    """
    js = ExScript.Compile.to_js! ast
    assert js <> "\n" == """
    ExScript.Modules.HelloWorld = {
        hi() {
            return 'hi';
        },
        bai() {
            return 1 + 1;
        }
    }
    """
  end

  test "compiles multiline module functions" do
    ast = Code.string_to_quoted! """
    defmodule Hello.World do
      def hi do
        a = 1
        a
      end
    end
    """
    js = ExScript.Compile.to_js! ast
    assert js <> "\n" == """
    ExScript.Modules.HelloWorld = {
        hi() {
            const a = 1;
            return a;
        }
    }
    """
  end

  test "compiles basic function calls" do
    js = ExScript.Compile.to_js! quote do: IO.puts("a")
    assert js <> "\n" == """
    ExScript.Modules.IO.puts('a')
    """
  end

  test "compiles external module function calls" do
    ast = Code.string_to_quoted! """
    defmodule Hello do
      def world(str), do: "World" <> str
    end
    defmodule Main do
      def init do
        Hello.world("Earth")
      end
    end
    """
    js = ExScript.Compile.to_js! ast
    assert js <> "\n" == """
    ExScript.Modules.Hello = {
        world(str) {
            return 'World' + str;
        }
    };
    ExScript.Modules.Main = {
        init() {
            return ExScript.Modules.Hello.world('Earth');
        }
    };
    """
  end

  test "compiles property function calls" do
    ast = Code.string_to_quoted! """
    defmodule Hello do
      def world(mod) do
        mod.fun("a")
      end
    end
    """
    js = ExScript.Compile.to_js! ast
    assert js <> "\n" == """
    ExScript.Modules.Hello = {
        world(mod) {
            return mod.fun('a');
        }
    }
    """
  end

  test "compiles dynamic property access" do
    ast = Code.string_to_quoted! """
    fn () ->
      foo = %{foo: "bar"}
      key = "bar"
      foo[key]
    end
    """
    js = ExScript.Compile.to_js! ast
    assert js <> "\n" == """
    () => {
        const key = 'bar';
        const foo = { foo: 'bar' };
        return foo[key];
    }
    """
  end

  test "compiles dynamic property access with function calls" do
    ast = Code.string_to_quoted! """
    defmodule Hello do
      def bar, do: "prop"
      def foo(a) do
        a.foo[bar()].baz "bam"
      end
    end
    """
    js = ExScript.Compile.to_js! ast
    assert js <> "\n" == """
    ExScript.Modules.Hello = {
        bar() {
            return 'prop';
        },
        foo(a) {
            return a.foo[this.bar()].baz('bam');
        }
    }
    """
  end

  test "compiles list ++ operators" do
    ast = Code.string_to_quoted! "[1, 2] ++ [3, 4]"
    js = ExScript.Compile.to_js! ast
    assert js <> "\n" == """
    [
        1,
        2
    ].concat([
        3,
        4
    ])
    """
  end

  test "compiles if expressions" do
    js = ExScript.Compile.to_js! quote do: a = if true, do: "hi", else: "bai"
    assert js == "const a = true ? 'hi' : 'bai';"
  end

  test "compiles cond expressions" do
    ast = Code.string_to_quoted! """
    val = cond do
      1 + 1 == 2 -> "hai"
      false -> "bai"
    end
    """
    js = ExScript.Compile.to_js! ast
    assert js <> "\n" == """
    const val = (() => {
        if (1 + 1 === 2) {
            return 'hai';
        } else if (false) {
            return 'bai';
        }
    })();
    """
  end

  test "compiles long bodied cond expressions" do
    ast = Code.string_to_quoted! """
    val = cond do
      1 + 1 == 2 ->
        a = "foo"
        b = "bar"
        a <> b
      false -> "bai"
    end
    """
    js = ExScript.Compile.to_js! ast
    assert js <> "\n" == """
    const val = (() => {
        if (1 + 1 === 2) {
            const b = 'bar';
            const a = 'foo';
            return a + b;
        } else if (false) {
            return 'bai';
        }
    })();
    """
  end

  test "compiles long cond expressions" do
    ast = Code.string_to_quoted! """
    val = cond do
      0 -> "a"
      1 -> "b"
      3 -> "c"
    end
    """
    js = ExScript.Compile.to_js! ast
    assert js <> "\n" == """
    const val = (() => {
        if (0) {
            return 'a';
        } else if (1) {
            return 'b';
        } else if (3) {
            return 'c';
        }
    })();
    """
  end

  test "compiles case expressions" do
    ast = Code.string_to_quoted! """
    val = case "a" do
      "a" -> "a"
      _ -> "b"
    end
    """
    js = ExScript.Compile.to_js! ast
    assert js <> "\n" == """
    const val = (() => {
        if ('a' === 'a') {
            return 'a';
        } else if (true) {
            return 'b';
        }
    })();
    """
  end

  test "compiles pipeline operator" do
    js = ExScript.Compile.to_js! quote do: "a" |> IO.puts
    assert js <> "\n" == """
    ExScript.Modules.IO.puts('a')
    """
  end

  test "compiles pipeline operator with extra args" do
    js = ExScript.Compile.to_js! quote do: "a,b" |> String.split(",")
    assert js <> "\n" == """
    ExScript.Modules.String.split('a,b', ',')
    """
  end

  test "compiles list pattern matching" do
    js = ExScript.Compile.to_js! quote do: [a, b] = [1, 2]
    assert js <> "\n" == """
    const [a, b] = [
        1,
        2
    ];
    """
  end

  test "compiles head tail pattern matching" do
    js = ExScript.Compile.to_js! quote do: [a | b] = [1, 2, 3]
    assert js <> "\n" == """
    const [a, ...b] = [
        1,
        2,
        3
    ];
    """
  end

  test "compiles local functions" do
    ast = Code.string_to_quoted! """
    defmodule Hello.World do
      def hi, do: bai()
      def bai, do: "bai"
    end
    """
    js = ExScript.Compile.to_js! ast
    assert js <> "\n" == """
    ExScript.Modules.HelloWorld = {
        hi() {
            return this.bai();
        },
        bai() {
            return 'bai';
        }
    }
    """
  end

  @tag :skip
  test "compiles -- operators" do
  end

  test "compiles <> operators" do
    js = ExScript.Compile.to_js! quote do: "a" <> "b"
    assert js == "'a' + 'b'"
  end

  @tag :skip
  test "compiles or operators" do
  end

  @tag :skip
  test "compiles and operators" do
  end

  @tag :skip
  test "compiles || operators" do
  end

  @tag :skip
  test "compiles && operators" do
  end

  @tag :skip
  test "compiles not operators" do
  end

  @tag :skip
  test "compiles ==, !=, ===, !==, <=, >=, <, and > operators" do
  end

  @tag :skip
  test "compiles pids" do
  end

  @tag :skip
  test "compiles tuples" do
  end
end
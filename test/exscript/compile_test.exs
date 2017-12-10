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

  test "compiles kernel functions" do
    js = ExScript.Compile.to_js! quote do: is_boolean(true)
    assert js == "ExScript.Modules.Kernel.is_boolean(true)"
    js = ExScript.Compile.to_js! quote do: is_list(true)
    assert js == "ExScript.Modules.Kernel.is_list(true)"
    js = ExScript.Compile.to_js! quote do: is_nil(true)
    assert js == "ExScript.Modules.Kernel.is_nil(true)"
    js = ExScript.Compile.to_js! quote do: length("a")
    assert js == "ExScript.Modules.Kernel.length('a')"
  end

  test "compiles kernel functions in function body" do
    js = ExScript.Compile.to_js! Code.string_to_quoted! """
    fn ->
      a = 1
      length a
    end
  """
  assert js <> "\n" == """
  () => {
      const a = 1;
      return ExScript.Modules.Kernel.length(a);
  }
  """
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
    assert js == "Symbol('hello')"
  end

  test "compiles strings" do
    js = ExScript.Compile.to_js! quote do: "Hello"
    assert js == "'Hello'"
  end

  test "compiles anonymous functions" do
    js = ExScript.Compile.to_js! quote do: fn (a, b) -> "hi" end
    assert js <> "\n" == """
    (a, b) => {
        return 'hi';
    }
    """
  end

  test "compiles multiline functions" do
    js = ExScript.Compile.to_js! Code.string_to_quoted! """
      fn ->
        a = 1
        b = 2
        a + b
      end
    """
    assert js <> "\n" == """
    () => {
        const a = 1;
        const b = 2;
        return a + b;
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

  test "compiles tuples" do
    js = ExScript.Compile.to_js! quote do: a = {"a", "b"}
    assert js <> "\n" == """
    const a = new ExScript.Types.Tuple('a', 'b');
    """
  end

  test "compiles maps" do
    js = ExScript.Compile.to_js! quote do: %{foo: IO.puts()}
    assert js <> "\n" == """
    { foo: ExScript.Modules.IO.puts() }
    """
  end

  test "compiles maps with function keys" do
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

  test "compiles module function args in the right order" do
    ast = Code.string_to_quoted! """
    defmodule Hello.World do
      def hi(a, b) do
        a
      end
    end
    """
    js = ExScript.Compile.to_js! ast
    assert js <> "\n" == """
    ExScript.Modules.HelloWorld = {
        hi(a, b) {
            return a;
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
        const foo = { foo: 'bar' };
        const key = 'bar';
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

  test "compiles local function calls" do
    ast = Code.string_to_quoted! """
    a = fn () -> "foo" end
    a.()
    """
    js = ExScript.Compile.to_js! ast
    assert js <> "\n" == """
    const a = () => {
        return 'foo';
    };;
    a();
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

  test "compiles if expressions with blocks" do
    ast = Code.string_to_quoted! """
    a = if true do
      b = "a"
      b <> "hi"
    else
      a = "b"
      a <> "c"
    end
    """
    js = ExScript.Compile.to_js! ast
    assert js <> "\n" == """
    const a = true ? (() => {
        const b = 'a';
        return b + 'hi';
    })() : (() => {
        const a = 'b';
        return a + 'c';
    })();
    """
  end

  test "compiles blocks that return assignment" do
    ast = Code.string_to_quoted! """
    a = if true do
      c = "a"
      a = "c"
    else
      "b"
    end
    """
    js = ExScript.Compile.to_js! ast
    assert js <> "\n" == """
    const a = true ? (() => {
        const c = 'a';
        const a = 'c';
        return a;
    })() : 'b';
    """
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
            const a = 'foo';
            const b = 'bar';
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

  test "compiles local function references" do
    ast = Code.string_to_quoted! """
    defmodule Hello.World do
      def hi, do: [:a, &bai/1]
      def bai, do: "bai"
    end
    """
    js = ExScript.Compile.to_js! ast
    assert js <> "\n" == """
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
    }
    """
  end


  test "compiles tuple pattern matching" do
    ast = Code.string_to_quoted! """
    {a, b} = {"a", "b"}
    """
    js = ExScript.Compile.to_js! ast
    assert js <> "\n" == """
    const [a, b] = new ExScript.Types.Tuple('a', 'b');
    """
  end

  test "compiles references to modules" do
    ast = Code.string_to_quoted! """
    IO.puts IO
    """
    js = ExScript.Compile.to_js! ast
    assert js <> "\n" == """
    ExScript.Modules.IO.puts(ExScript.Modules.IO)
    """
  end

  test "compiles <> operators" do
    js = ExScript.Compile.to_js! quote do: "a" <> "b"
    assert js == "'a' + 'b'"
  end

  test "compiles or operators" do
    js = ExScript.Compile.to_js! quote do: if true or true, do: "hi", else: "bai"
    assert js == "true || true ? 'hi' : 'bai'"
  end

  test "compiles and operators" do
    js = ExScript.Compile.to_js! quote do: if true and true, do: "hi", else: "bai"
    assert js == "true && true ? 'hi' : 'bai'"
  end

  test "compiles || operators" do
    js = ExScript.Compile.to_js! quote do: if true || true, do: "hi", else: "bai"
    assert js == "true || true ? 'hi' : 'bai'"
  end

  test "compiles && operators" do
    js = ExScript.Compile.to_js! quote do: if true && true, do: "hi", else: "bai"
    assert js == "true && true ? 'hi' : 'bai'"
  end

  test "compiles not operators" do
    js = ExScript.Compile.to_js! quote do: if not "foo", do: "hi", else: "bai"
    assert js == "!'foo' ? 'hi' : 'bai'"
  end

  test "compiles advanced not operators" do
    js = ExScript.Compile.to_js! quote do: if not IO.puts(), do: "hi", else: "bai"
    assert js == "!ExScript.Modules.IO.puts() ? 'hi' : 'bai'"
  end

  test "compiles embedded code" do
    ast = Code.string_to_quoted! """
    fn () ->
      a = "a"
      JS.embed "debugger"
      b = "b"
    end
    """
    js = ExScript.Compile.to_js! ast
    assert js <> "\n" == """
    () => {
        const a = 'a';
        debugger;
        const b = 'b';
        return b;
    }
    """
  end

  test "compiles string interpolation" do
    js = ExScript.Compile.to_js! quote do: "foo #{"bar"}"
    assert js == "`foo ${ 'bar' }`"
    js = ExScript.Compile.to_js! quote do: "foo #{"bar"} baz"
    assert js == "`foo ${ 'bar' } baz`"
    js = ExScript.Compile.to_js! quote do: "foo #{"bar" + "baz"}"
    assert js == "`foo ${ 'bar' + 'baz' }`"
    js = ExScript.Compile.to_js! quote do: "foo #{"bar" + "baz"} qux"
    assert js == "`foo ${ 'bar' + 'baz' } qux`"
  end

  test "compiles ? functions smartly" do
    js = ExScript.Compile.to_js! quote do: Keyword.keyword?("a")
    assert js == "ExScript.Modules.Keyword['keyword?']('a')"
  end

  test "compiles map pattern matching in function arguments" do
    ast = Code.string_to_quoted! """
    fn (%{a: b}) ->
      a
    end
    """
    js = ExScript.Compile.to_js! ast
    assert js <> "\n" == """
    ({a: b}) => {
        return a;
    }
    """
  end

  test "compiles tuple pattern matching in function arguments" do
    ast = Code.string_to_quoted! """
    fn ({a, b, c}) ->
      a
    end
    """
    js = ExScript.Compile.to_js! ast
    assert js <> "\n" == """
    ([a, b, c]) => {
        return a;
    }
    """
  end

  test "compiles double tuple pattern matching in function arguments" do
    ast = Code.string_to_quoted! """
    fn ({a, b}) ->
      a
    end
    """
    js = ExScript.Compile.to_js! ast
    assert js <> "\n" == """
    ([a, b]) => {
        return a;
    }
    """
  end

  test "compiles !=" do
    ast = Code.string_to_quoted! """
    a = if true != false, do: "hi", else: "bai"
    """
    js = ExScript.Compile.to_js! ast
    assert js <> "\n" == """
    const a = true !== false ? 'hi' : 'bai';
    """
  end

  test "compiles functions in keyword lists" do
    ast = Code.string_to_quoted! """
    a = [foo: fn -> "bar" end]
    """
    js = ExScript.Compile.to_js! ast
    assert js <> "\n" == """
    const a = [new ExScript.Types.Tuple(Symbol('foo'), () => {
            return 'bar';
        })];
    """
  end
  
  @tag :skip
  test "compiles ==, !=, ===, !==, <=, >=, <, and > operators" do
  end

  @tag :skip
  test "compiles pids" do
  end

  @tag :skip
  test "compiles -- operators" do
  end
end
defmodule ExScript.Compiler.ModulesTest do
  @moduledoc false

  use ExUnit.Case, async: true

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
    IO.puts('a')
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
    const {Hello} = ExScript.Modules;
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

  test "compiles local module functions" do
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

  test "compiles local module function references" do
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

  test "compiles references to module functions" do
    ast = Code.string_to_quoted! """
    IO.puts IO
    """
    js = ExScript.Compile.to_js! ast
    assert js <> "\n" == """
    IO.puts(IO)
    """
  end

  test "compiles moduledocs" do
    ast = Code.string_to_quoted! """
    defmodule Hi do
      @moduledoc "hi"
      def bai, do: "bai"
    end
    """
    js = ExScript.Compile.to_js! ast
    assert js <> "\n" == """
    ExScript.Modules.Hi = {
        bai() {
            return 'bai';
        }
    }
    """
  end

  test "compiles nested module references" do
    ast = Code.string_to_quoted! """
    defmodule Hello.Earth do
      def hi, do: "hi"
    end
    defmodule Hello.Mars do
      def hi, do: Hello.Earth.hi()
    end
    """
    js = ExScript.Compile.to_js! ast
    assert js <> "\n" == """
    const {HelloEarth} = ExScript.Modules;
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
    """
  end

  test "hoists the namepsace for readability" do
    ast = Code.string_to_quoted! """
    IO.puts "foo"
    JS.log "bar"
    """
    js = ExScript.Compile.to_js! ast
    assert js <> "\n" == """
    const {IO, JS} = ExScript.Modules;
    IO.puts('foo');
    JS.log('bar');
    """
  end
end

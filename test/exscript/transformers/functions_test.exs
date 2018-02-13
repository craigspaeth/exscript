defmodule ExScript.Compiler.FunctionsTest do
  use ExUnit.Case

  test "compiles anonymous functions" do
    js = ExScript.Compile.to_js!(quote do: fn a, b -> "hi" end)

    assert js <> "\n" == """
           (a, b) => {
               return 'hi';
           }
           """
  end

  test "compiles multiline functions" do
    js =
      ExScript.Compile.to_js!(
        Code.string_to_quoted!("""
          fn ->
            a = 1
            b = 2
            a + b
          end
        """)
      )

    assert js <> "\n" == """
           () => {
               const a = 1;
               const b = 2;
               return a + b;
           }
           """
  end

  test "compiles kernel functions" do
    js = ExScript.Compile.to_js!(quote do: is_boolean(true))
    assert js == "Kernel.is_boolean(true)"
    js = ExScript.Compile.to_js!(quote do: is_list(true))
    assert js == "Kernel.is_list(true)"
    js = ExScript.Compile.to_js!(quote do: is_nil(true))
    assert js == "Kernel.is_nil(true)"
    js = ExScript.Compile.to_js!(quote do: length("a"))
    assert js == "Kernel.length('a')"
  end

  test "compiles kernel functions in function body" do
    js =
      ExScript.Compile.to_js!(
        Code.string_to_quoted!("""
          fn ->
            a = 1
            length a
          end
        """)
      )

    assert js <> "\n" == """
           () => {
               const a = 1;
               return Kernel.length(a);
           }
           """
  end

  test "compiles lexically local function calls" do
    ast =
      Code.string_to_quoted!("""
      a = fn () -> "foo" end
      a.()
      """)

    js = ExScript.Compile.to_js!(ast)

    assert js <> "\n" == """
           const a = () => {
               return 'foo';
           };;
           a();
           """
  end

  test "compiles blocks that return assignment" do
    ast =
      Code.string_to_quoted!("""
      a = if true do
        c = "a"
        a = "c"
      else
        "b"
      end
      """)

    js = ExScript.Compile.to_js!(ast)

    assert js <> "\n" == """
           const a = true ? (() => {
               const c = 'a';
               const a = 'c';
               return a;
           })() : 'b';
           """
  end

  test "compiles map pattern matching in function arguments" do
    ast =
      Code.string_to_quoted!("""
      fn (%{a: b}) ->
        a
      end
      """)

    js = ExScript.Compile.to_js!(ast)

    assert js <> "\n" == """
           ({a: b}) => {
               return a;
           }
           """
  end

  test "compiles tuple pattern matching in function arguments" do
    ast =
      Code.string_to_quoted!("""
      fn ({a, b, c}) ->
        a
      end
      """)

    js = ExScript.Compile.to_js!(ast)

    assert js <> "\n" == """
           ([a, b, c]) => {
               return a;
           }
           """
  end

  test "compiles double tuple pattern matching in function arguments" do
    ast =
      Code.string_to_quoted!("""
      fn ({a, b}) ->
        a
      end
      """)

    js = ExScript.Compile.to_js!(ast)

    assert js <> "\n" == """
           ([a, b]) => {
               return a;
           }
           """
  end

  test "compiles ? functions smartly" do
    js = ExScript.Compile.to_js!(quote do: Keyword.keyword?("a"))
    assert js == "Keyword['keyword?']('a')"
  end

  test "compiles functions in keyword lists" do
    ast =
      Code.string_to_quoted!("""
      a = [foo: fn -> "bar" end]
      """)

    js = ExScript.Compile.to_js!(ast)

    assert js <> "\n" == """
           const a = [new ExScript.Types.Tuple(Symbol('foo'), () => {
                   return 'bar';
               })];
           """
  end

  @tag :cur
  test "declares let variables at the top of a block for reassignment" do
    ex = """
    defmodule Foo do
      def a do
        b = "bar"
        c = fn ->
          b = "qux"
        end
        b = "baz"
      end
      def b do
        b = "bam"
        c = "foo"
        b = "bop"
        c = "baz"
      end
    end
    """

    js = ExScript.Compile.to_js!(Code.string_to_quoted!(ex))

    expected = """
    ExScript.Modules.Foo = {
        a() {
            let b, c;
            b = 'bar';
            c = () => {
                let b;
                b = 'qux';
                return b;
            };
            b = 'baz';
            return b;
        },
        b() {
            let b, c;
            b = 'bam';
            c = 'foo';
            b = 'bop';
            c = 'baz';
            return c;
        }
    }
    """

    assert js <> "\n" == expected
  end
end

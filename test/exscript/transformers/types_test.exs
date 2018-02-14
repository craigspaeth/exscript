defmodule ExScript.Compiler.TypesTest do
  use ExUnit.Case

  test "compiles atoms" do
    js = ExScript.Compile.to_js!(quote do: :hello)
    assert js == "Symbol('hello');"
  end

  test "compiles strings" do
    js = ExScript.Compile.to_js!(quote do: "Hello")
    assert js == "'Hello';"
  end

  test "compiles lists" do
    js = ExScript.Compile.to_js!(quote do: [1, 2, 3])

    assert js <> "\n" == """
           [
               1,
               2,
               3
           ];
           """
  end

  test "compiles tuples" do
    js = ExScript.Compile.to_js!(quote do: a = {"a", "b"})

    assert js <> "\n" == """
           let a;
           a = new ExScript.Types.Tuple('a', 'b');
           """
  end

  test "compiles maps" do
    js = ExScript.Compile.to_js!(quote do: %{foo: IO.puts()})

    assert js <> "\n" == """
           ({ foo: IO.puts() });
           const {IO} = ExScript.Modules;
           """
  end

  test "compiles maps with function keys" do
    js = ExScript.Compile.to_js!(quote do: %{foo: "bar", baz: "qux"})

    assert js <> "\n" == """
           ({
               foo: 'bar',
               baz: 'qux'
           });
           """
  end

  test "compiles nil" do
    js = ExScript.Compile.to_js!(quote do: nil)
    assert js == "null;"
  end

  @tag :skip
  test "compiles pids" do
  end
end

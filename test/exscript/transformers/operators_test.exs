defmodule ExScript.Compiler.OperatorsTest do
  use ExUnit.Case

  test "compiles basic arithmetic" do
    js = ExScript.Compile.to_js!(quote do: 1 + 2 * 3 / 4 - 5)
    assert js == "1 + 2 * 3 / 4 - 5"
  end

  test "compiles assignment" do
    js = ExScript.Compile.to_js!(quote do: a = 1)
    assert js == "const a = 1;"
  end

  test "compiles equality" do
    js = ExScript.Compile.to_js!(quote do: true == false)
    assert js == "true === false"
  end

  test "compiles list > operators" do
    ast = Code.string_to_quoted!("1 > 2")
    js = ExScript.Compile.to_js!(ast)

    assert js <> "\n" == """
           1 > 2
           """
  end

  test "compiles pipeline operator" do
    js = ExScript.Compile.to_js!(quote do: "a" |> IO.puts())

    assert js <> "\n" == """
           IO.puts('a')
           """
  end

  test "compiles pipeline operator with extra args" do
    js = ExScript.Compile.to_js!(quote do: "a,b" |> String.split(","))

    assert js <> "\n" == """
           String.split('a,b', ',')
           """
  end

  test "compiles list pattern matching" do
    js = ExScript.Compile.to_js!(quote do: [a, b] = [1, 2])

    assert js <> "\n" == """
           const [a, b] = [
               1,
               2
           ];
           """
  end

  test "compiles head tail pattern matching" do
    js = ExScript.Compile.to_js!(quote do: [a | b] = [1, 2, 3])

    assert js <> "\n" == """
           const [a, ...b] = [
               1,
               2,
               3
           ];
           """
  end

  test "compiles tuple pattern matching" do
    ast =
      Code.string_to_quoted!("""
      {a, b} = {"a", "b"}
      """)

    js = ExScript.Compile.to_js!(ast)

    assert js <> "\n" == """
           const [a, b] = new ExScript.Types.Tuple('a', 'b');
           """
  end

  test "compiles <> operators" do
    js = ExScript.Compile.to_js!(quote do: "a" <> "b")
    assert js == "'a' + 'b'"
  end

  test "compiles or operators" do
    js = ExScript.Compile.to_js!(quote do: if(true or true, do: "hi", else: "bai"))
    assert js == "true || true ? 'hi' : 'bai'"
  end

  test "compiles and operators" do
    js = ExScript.Compile.to_js!(quote do: if(true and true, do: "hi", else: "bai"))
    assert js == "true && true ? 'hi' : 'bai'"
  end

  test "compiles || operators" do
    js = ExScript.Compile.to_js!(quote do: if(true || true, do: "hi", else: "bai"))
    assert js == "true || true ? 'hi' : 'bai'"
  end

  test "compiles && operators" do
    js = ExScript.Compile.to_js!(quote do: if(true && true, do: "hi", else: "bai"))
    assert js == "true && true ? 'hi' : 'bai'"
  end

  test "compiles not operators" do
    js = ExScript.Compile.to_js!(quote do: if(not "foo", do: "hi", else: "bai"))
    assert js == "!'foo' ? 'hi' : 'bai'"
  end

  test "compiles advanced not operators" do
    js = ExScript.Compile.to_js!(quote do: if(not IO.puts(), do: "hi", else: "bai"))
    assert js == "!IO.puts() ? 'hi' : 'bai'"
  end

  test "compiles string interpolation" do
    js = ExScript.Compile.to_js!(quote do: "foo #{"bar"}")
    assert js == "`foo ${ 'bar' }`"
    js = ExScript.Compile.to_js!(quote do: "foo #{"bar"} baz")
    assert js == "`foo ${ 'bar' } baz`"
    js = ExScript.Compile.to_js!(quote do: "foo #{"bar" + "baz"}")
    assert js == "`foo ${ 'bar' + 'baz' }`"
    js = ExScript.Compile.to_js!(quote do: "foo #{"bar" + "baz"} qux")
    assert js == "`foo ${ 'bar' + 'baz' } qux`"
  end

  test "compiles !=" do
    ast =
      Code.string_to_quoted!("""
      a = if true != false, do: "hi", else: "bai"
      """)

    js = ExScript.Compile.to_js!(ast)

    assert js <> "\n" == """
           const a = true !== false ? 'hi' : 'bai';
           """
  end

  test "compiles list ++ operators" do
    ast = Code.string_to_quoted!("[1, 2] ++ [3, 4]")
    js = ExScript.Compile.to_js!(ast)

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

  @tag :skip
  test "compiles ==, !=, ===, !==, <=, >=, <, and > operators" do
  end

  @tag :skip
  test "compiles -- operators" do
  end
end

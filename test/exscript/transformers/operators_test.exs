defmodule ExScript.Compiler.OperatorsTest do
  use ExUnit.Case

  test "compiles basic arithmetic" do
    ExScript.TestHelper.compare(
      """
      1 + 2 * 3 / 4 - 5
      """,
      """
      1 + 2 * 3 / 4 - 5;
      """
    )
  end

  test "compiles assignment" do
    ExScript.TestHelper.compare(
      """
      a = 1
      """,
      """
      let a;
      a = 1;
      """
    )
  end

  test "compiles equality" do
    ExScript.TestHelper.compare(
      """
      true == false
      """,
      """
      true === false;
      """
    )
  end

  test "compiles list > operators" do
    ExScript.TestHelper.compare(
      """
      1 > 2
      """,
      """
      1 > 2;
      """
    )
  end

  test "compiles pipeline operator" do
    ExScript.TestHelper.compare(
      """
      "a" |> IO.puts()
      """,
      """
      IO.puts('a');
      """
    )
  end

  test "compiles pipelines with local function calls" do
    ExScript.TestHelper.compare(
      """
      :a@b |> to_string()
      """,
      """
      this.to_string(Symbol('a@b'));
      """
    )
  end

  test "compiles pipeline operator with extra args" do
    ExScript.TestHelper.compare(
      """
      "a,b" |> String.split(",")
      """,
      """
      String.split('a,b', ',');
      """
    )
  end

  test "compiles list pattern matching" do
    ExScript.TestHelper.compare(
      """
      [a, b] = [1, 2]
      """,
      """
      let a, b;
      [a, b] = [
          1,
          2
      ];
      """
    )
  end

  test "compiles head tail pattern matching" do
    ExScript.TestHelper.compare(
      """
      [a | b] = [1, 2, 3]
      """,
      """
      let a, b;
      [a, ...b] = [
          1,
          2,
          3
      ];
      """
    )
  end

  test "compiles tuple pattern matching" do
    ExScript.TestHelper.compare(
      """
      {a, b} = {"a", "b"}
      """,
      """
      let a, b;
      [a, b] = new Tup('a', 'b');
      """
    )
  end

  test "compiles advanced tuple pattern matching" do
    ExScript.TestHelper.compare(
      """
      {a, b, c} = foo()
      """,
      """
      let a, b, c;
      [a, b, c] = this.foo();
      """
    )
  end

  test "compiles <> operators" do
    ExScript.TestHelper.compare(
      """
      "a" <> "b"
      """,
      """
      'a' + 'b';
      """
    )
  end

  test "compiles or operators" do
    ExScript.TestHelper.compare(
      """
      if(true or true, do: "hi", else: "bai")
      """,
      """
      true || true ? 'hi' : 'bai';
      """
    )
  end

  test "compiles and operators" do
    ExScript.TestHelper.compare(
      """
      if(true and true, do: "hi", else: "bai")
      """,
      """
      true && true ? 'hi' : 'bai';
      """
    )
  end

  test "compiles || operators" do
    ExScript.TestHelper.compare(
      """
      if(true || true, do: "hi", else: "bai")
      """,
      """
      true || true ? 'hi' : 'bai';
      """
    )
  end

  test "compiles && operators" do
    ExScript.TestHelper.compare(
      """
      if(true && true, do: "hi", else: "bai")
      """,
      """
      true && true ? 'hi' : 'bai';
      """
    )
  end

  test "compiles not operators" do
    ExScript.TestHelper.compare(
      """
      if(not "foo", do: "hi", else: "bai")
      """,
      """
      !'foo' ? 'hi' : 'bai';
      """
    )
  end

  test "compiles advanced not operators" do
    ExScript.TestHelper.compare(
      """
      if(not IO.puts(), do: "hi", else: "bai")
      """,
      """
      !IO.puts() ? 'hi' : 'bai';
      """
    )
  end

  test "compiles string interpolation" do
    ExScript.TestHelper.compare("\"foo \#{\"bar\"}\"", "`foo ${ 'bar' }`;\n")
    ExScript.TestHelper.compare("\"foo \#{\"bar\"} baz\"", "`foo ${ 'bar' } baz`;\n")
    ExScript.TestHelper.compare("\"foo \#{\"bar\" + \"baz\"}\"", "`foo ${ 'bar' + 'baz' }`;\n")

    ExScript.TestHelper.compare(
      "\"foo \#{\"bar\" + \"baz\"} qux\"",
      "`foo ${ 'bar' + 'baz' } qux`;\n"
    )
  end

  test "compiles !=" do
    ExScript.TestHelper.compare(
      """
      a = if true != false, do: "hi", else: "bai"
      """,
      """
      let a;
      a = true !== false ? 'hi' : 'bai';
      """
    )
  end

  test "compiles list ++ operators" do
    ExScript.TestHelper.compare(
      """
      [1, 2] ++ [3, 4]
      """,
      """
      [
          1,
          2
      ].concat([
          3,
          4
      ]);
      """
    )
  end

  @tag :skip
  test "compiles ==, !=, ===, !==, <=, >=, <, and > operators" do
  end

  @tag :skip
  test "compiles -- operators" do
  end
end

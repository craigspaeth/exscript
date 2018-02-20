defmodule ExScript.Compiler.TypesTest do
  use ExUnit.Case

  test "compiles atoms" do
    ExScript.TestHelper.compare(
      """
      :hello
      """,
      """
      Symbol('hello');
      """
    )
  end

  test "compiles strings" do
    ExScript.TestHelper.compare(
      """
      "Hello"
      """,
      """
      'Hello';
      """
    )
  end

  test "compiles lists" do
    ExScript.TestHelper.compare(
      """
      [1, 2, 3]
      """,
      """
      [
          1,
          2,
          3
      ];
      """
    )
  end

  test "compiles tuples" do
    ExScript.TestHelper.compare(
      """
      a = {"a", "b"}
      """,
      """
      let a;
      a = new Tup('a', 'b');
      """
    )
  end

  test "compiles maps" do
    ExScript.TestHelper.compare(
      """
      %{foo: IO.puts()}
      """,
      """
      ({ foo: IO.puts() });
      """
    )
  end

  test "compiles maps with function keys" do
    ExScript.TestHelper.compare(
      """
      %{foo: "bar", baz: "qux"}
      """,
      """
      ({
          foo: 'bar',
          baz: 'qux'
      });
      """
    )
  end

  test "compiles nil" do
    ExScript.TestHelper.compare(
      """
      nil
      """,
      """
      null;
      """
    )
  end

  test "compiles dynamic map keys" do
    ExScript.TestHelper.compare(
      """
      a = :a
      map = %{a => "b"}
      """,
      """
      let a, map;
      a = Symbol('a');
      map = { [a]: 'b' };
      """
    )
  end

  @tag :skip
  test "compiles pids" do
  end
end

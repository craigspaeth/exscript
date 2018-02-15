defmodule ExScript.Compiler.ControlFlowTest do
  use ExUnit.Case

  test "compiles if expressions" do
    ExScript.TestHelper.compare(
      """
      a = if true, do: "hi", else: "bai"
      """,
      """
      let a;
      a = true ? 'hi' : 'bai';
      """
    )
  end

  test "compiles if expressions with blocks" do
    ExScript.TestHelper.compare(
      """
      a = if true do
        b = "a"
        b <> "hi"
      else
        a = "b"
        a <> "c"
      end
      """,
      """
      let a;
      a = true ? (() => {
          let b;
          b = 'a';
          return b + 'hi';
      })() : (() => {
          let a;
          a = 'b';
          return a + 'c';
      })();
      """
    )
  end

  test "compiles cond expressions" do
    ExScript.TestHelper.compare(
      """
      val = cond do
        1 + 1 == 2 -> "hai"
        false -> "bai"
      end
      """,
      """
      let val;
      val = (() => {
          if (1 + 1 === 2) {
              return 'hai';
          } else if (false) {
              return 'bai';
          }
      })();
      """
    )
  end

  test "compiles long bodied cond expressions" do
    ExScript.TestHelper.compare(
      """
      val = cond do
        1 + 1 == 2 ->
          a = "foo"
          b = "bar"
          a <> b
        false -> "bai"
      end
      """,
      """
      let val;
      val = (() => {
          if (1 + 1 === 2) {
              let a, b;
              a = 'foo';
              b = 'bar';
              return a + b;
          } else if (false) {
              return 'bai';
          }
      })();
      """
    )
  end

  test "compiles long cond expressions" do
    ExScript.TestHelper.compare(
      """
      val = cond do
        0 -> "a"
        1 -> "b"
        3 -> "c"
      end
      """,
      """
      let val;
      val = (() => {
          if (0) {
              return 'a';
          } else if (1) {
              return 'b';
          } else if (3) {
              return 'c';
          }
      })();
      """
    )
  end

  test "compiles case expressions" do
    ExScript.TestHelper.compare(
      """
      val = case "a" do
        "a" -> "a"
        _ -> "b"
      end
      """,
      """
      let val;
      val = (() => {
          if ('a' === 'a') {
              return 'a';
          } else if (true) {
              return 'b';
          }
      })();
      """
    )
  end
end

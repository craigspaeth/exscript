defmodule ExScript.Compiler.ControlFlowTest do
  use ExUnit.Case

  test "compiles if expressions" do
    js = ExScript.Compile.to_js!(quote do: a = if(true, do: "hi", else: "bai"))
    assert js == "const a = true ? 'hi' : 'bai';"
  end

  test "compiles if expressions with blocks" do
    ast =
      Code.string_to_quoted!("""
      a = if true do
        b = "a"
        b <> "hi"
      else
        a = "b"
        a <> "c"
      end
      """)

    js = ExScript.Compile.to_js!(ast)

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

  test "compiles cond expressions" do
    ast =
      Code.string_to_quoted!("""
      val = cond do
        1 + 1 == 2 -> "hai"
        false -> "bai"
      end
      """)

    js = ExScript.Compile.to_js!(ast)

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
    ast =
      Code.string_to_quoted!("""
      val = cond do
        1 + 1 == 2 ->
          a = "foo"
          b = "bar"
          a <> b
        false -> "bai"
      end
      """)

    js = ExScript.Compile.to_js!(ast)

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
    ast =
      Code.string_to_quoted!("""
      val = cond do
        0 -> "a"
        1 -> "b"
        3 -> "c"
      end
      """)

    js = ExScript.Compile.to_js!(ast)

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
    ast =
      Code.string_to_quoted!("""
      val = case "a" do
        "a" -> "a"
        _ -> "b"
      end
      """)

    js = ExScript.Compile.to_js!(ast)

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
end

defmodule JMES.ParserTest do
  use ExUnit.Case

  import AssertValue

  alias JMES.Parser

  describe "parse/1" do
    test "whitespace" do
      assert_value parse(" \ta\n\r") == {:id, "a"}
    end

    test "wildcard" do
      assert_value parse("*") == :wildcard
      assert_value parse("*.b.c") == {:child, [child: [:wildcard, {:id, "b"}], id: "c"]}
      assert_value parse("[*]") == {:list, [:wildcard]}
      assert_value parse("[[*],*]") == {:list, [{:list, [:wildcard]}, :wildcard]}
    end

    test "id" do
      assert_value parse("a") == {:id, "a"}
    end

    test "node" do
      assert_value parse("@") == :node
    end

    test "raw" do
      assert_value parse("'hello world'") == {:string, "hello world"}
    end

    test "json" do
      assert_value parse("`true`") == {:json, "true"}
    end

    test "paren" do
      assert_value parse("(a)") == {:id, "a"}
    end

    test "pipe" do
      assert_value parse("a | b") == {:pipe, [id: "a", id: "b"]}
    end

    test "or" do
      assert_value parse("a || b") == {:or, [id: "a", id: "b"]}
    end

    test "and" do
      assert_value parse("a && b") == {:and, [id: "a", id: "b"]}
    end

    test "eq" do
      assert_value parse("a == b") == {:eq, [id: "a", id: "b"]}
    end

    test "neq" do
      assert_value parse("a != b") == {:neq, [id: "a", id: "b"]}
    end

    test "lt" do
      assert_value parse("a < b") == {:lt, [id: "a", id: "b"]}
    end

    test "gt" do
      assert_value parse("a > b") == {:gt, [id: "a", id: "b"]}
    end

    test "lte" do
      assert_value parse("a <= b") == {:lte, [id: "a", id: "b"]}
    end

    test "gte" do
      assert_value parse("a >= b") == {:gte, [id: "a", id: "b"]}
    end

    test "not" do
      assert_value parse("!a") == {:not, {:id, "a"}}
      assert_value parse("!!a") == {:not, {:not, {:id, "a"}}}
    end

    test "child" do
      assert_value parse("a.b") == {:child, [id: "a", id: "b"]}
      assert_value parse("a.*") == {:child, [{:id, "a"}, :wildcard]}
      assert_value parse("a.[b]") == {:child, [id: "a", list: [id: "b"]]}
      assert_value parse("a.{c: d}") == {:child, [id: "a", dict: [["c", {:id, "d"}]]]}
      assert_value parse("a.b()") == {:child, [id: "a", call: ["b", []]]}
    end

    test "flatten" do
      assert_value parse("[]") == :flatten
      assert_value parse("a[]") == {:flatten, {:id, "a"}}
    end

    test "index" do
      assert_value parse("[0]") == {:index, [nil, 0]}
      assert_value parse("a[0]") == {:index, [{:id, "a"}, 0]}
    end

    test "slice" do
      assert_value parse("[:]") == {:slice, [nil, [nil, nil, nil]]}
      assert_value parse("[:1]") == {:slice, [nil, [nil, 1, nil]]}
      assert_value parse("[0:]") == {:slice, [nil, [0, nil, nil]]}
      assert_value parse("[0:1]") == {:slice, [nil, [0, 1, nil]]}
      assert_value parse("[::]") == {:slice, [nil, [nil, nil, nil]]}
      assert_value parse("[::2]") == {:slice, [nil, [nil, nil, 2]]}
      assert_value parse("[:1:]") == {:slice, [nil, [nil, 1, nil]]}
      assert_value parse("[:1:2]") == {:slice, [nil, [nil, 1, 2]]}
      assert_value parse("[0::]") == {:slice, [nil, [0, nil, nil]]}
      assert_value parse("[0::2]") == {:slice, [nil, [0, nil, 2]]}
      assert_value parse("[0:1:]") == {:slice, [nil, [0, 1, nil]]}
      assert_value parse("[0:1:2]") == {:slice, [nil, [0, 1, 2]]}
      assert_value parse("a[0:1:2]") == {:slice, [{:id, "a"}, [0, 1, 2]]}
    end

    test "filter" do
      assert_value parse("[? a]") == {:filter, [nil, {:id, "a"}]}
      assert_value parse("a[? b]") == {:filter, [id: "a", id: "b"]}
    end

    test "list" do
      assert_value parse("[a]") == {:list, [id: "a"]}
      assert_value parse("[a,b]") == {:list, [id: "a", id: "b"]}
      assert_value parse("[a,]") == :error
    end

    test "dict" do
      assert_value parse("{a: b}") == {:dict, [["a", {:id, "b"}]]}
      assert_value parse("{a: b, c: d}") == {:dict, [["a", {:id, "b"}], ["c", {:id, "d"}]]}
      assert_value parse("{a:}") == :error
      assert_value parse("{a: b,}") == :error
      assert_value parse("{}") == :error
      assert_value parse("{a:, c: d}") == :error
    end

    test "call" do
      assert_value parse("a()") == {:call, ["a", []]}
      assert_value parse("a(b)") == {:call, ["a", [id: "b"]]}
      assert_value parse("a(b,c)") == {:call, ["a", [id: "b", id: "c"]]}
      assert_value parse("a(&b)") == {:call, ["a", [quote: {:id, "b"}]]}
      assert_value parse("a(&b,c)") == {:call, ["a", [quote: {:id, "b"}, id: "c"]]}
      assert_value parse("a(&b,&c)") == {:call, ["a", [quote: {:id, "b"}, quote: {:id, "c"}]]}
      assert_value parse("a(b,)") == :error
    end
  end

  defp parse(expr) do
    case Parser.parse(expr) do
      {:ok, ast} -> ast
      _ -> :error
    end
  end
end

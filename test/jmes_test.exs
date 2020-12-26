defmodule JMESTest do
  use ExUnit.Case
  doctest JMES

  import AssertValue

  describe "search/2" do
    test "wildcard" do
      assert_value search("*", %{"a" => "b", "c" => "d"}) == ["b", "d"]
      assert_value search("[*]", [1, 2, 3]) == [1, 2, 3]
      assert_value search("[[*],*]", %{"type" => "object"}) == [nil, ["object"]]
    end

    test "identifier" do
      assert_value search("a", %{"a" => "b"}) == "b"
      assert_value search("a", %{a: "b"}) == "b"
      assert_value search("b", %{"a" => "b"}) == nil
      assert_value search("b", true) == nil
    end

    test "literals" do
      assert_value search("'a'", %{"a" => "b"}) == "a"
      assert_value search("`true`", nil) == true
      assert_value search(~S{`"\`hello world\`"`}, nil) == "`hello world`"
      assert_value search(~S{`["\`hello world\`"]`}, nil) == ["`hello world`"]
    end

    test "node" do
      assert_value search("@", 10) == 10
    end

    test "pipe" do
      persons = %{"a" => %{"name" => "alice"}, "b" => %{"name" => "bob"}}
      assert_value search("* | [1].name", persons) == "bob"
    end

    test "logical" do
      assert_value search("'a' == 'a'", %{"a" => "b"}) == true
      assert_value search("'a' == 'b'", %{"a" => "b"}) == false
      assert_value search("'a' != 'a'", %{"a" => "b"}) == false
      assert_value search("'a' != 'b'", %{"a" => "b"}) == true
      assert_value search("`1` < `2`", nil) == true
      assert_value search("`2` < `1`", nil) == false
      assert_value search("`2` < `true`", nil) == {:error, :invalid_type}
      assert_value search("`1` > `2`", nil) == false
      assert_value search("`2` > `1`", nil) == true
      assert_value search("`2` > `true`", nil) == {:error, :invalid_type}
      assert_value search("`1` <= `2`", nil) == true
      assert_value search("`2` <= `1`", nil) == false
      assert_value search("`2` <= `2`", nil) == true
      assert_value search("`2` <= `true`", nil) == {:error, :invalid_type}
      assert_value search("`1` >= `2`", nil) == false
      assert_value search("`2` >= `1`", nil) == true
      assert_value search("`2` >= `2`", nil) == true
      assert_value search("`2` >= `true`", nil) == {:error, :invalid_type}
      assert_value search("!`true`", nil) == false
      assert_value search("!`false`", nil) == true
      assert_value search("!`null`", nil) == true
      assert_value search("!`1`", nil) == false
    end

    test "child" do
      assert_value search("a.b", %{"a" => %{"b" => "c"}}) == "c"
      assert_value search("a.[b,d]", %{"a" => %{"b" => "c", "d" => "e"}}) == ["c", "e"]

      persons = %{"a" => %{"name" => "alice"}, "b" => %{"name" => "bob"}}

      assert_value search("*.name", persons) ==
                     ["alice", "bob"]

      persons = %{"a" => %{"name" => "alice"}, "b" => %{"name" => "bob"}, "c" => nil}

      assert_value search("*.name", persons) ==
                     ["alice", "bob"]
    end

    test "flatted" do
      assert_value search("[]", [0, 1, 2]) == [0, 1, 2]
      assert_value search("[]", [0, [1, 2]]) == [0, 1, 2]
      assert_value search("[]", [0, [[1], 2]]) == [0, [1], 2]

      assert_value search("a[]", %{"a" => [0, [1, 2]]}) ==
                     [0, 1, 2]
    end

    test "index" do
      assert_value search("[1]", [0, 1, 2]) == 1
      assert_value search("[-1]", [0, 1, 2]) == 2
      assert_value search("[4]", [0, 1, 2]) == nil
      assert_value search("a[2]", %{"a" => [0, 1, 2]}) == 2
    end

    test "slice" do
      assert_value search("[:]", [0, 1, 2, 3]) == [0, 1, 2, 3]
      assert_value search("[:3]", [0, 1, 2, 3]) == [0, 1, 2]
      assert_value search("[:-2]", [0, 1, 2, 3]) == [0, 1]
      assert_value search("[1:]", [0, 1, 2, 3]) == [1, 2, 3]
      assert_value search("[1:3]", [0, 1, 2, 3]) == [1, 2]
      assert_value search("[3:1]", [0, 1, 2, 3]) == []
      assert_value search("[0:4:1]", [0, 1, 2, 3]) == [0, 1, 2, 3]
      assert_value search("[::2]", [0, 1, 2, 3]) == [0, 2]
      assert_value search("[1::2]", [0, 1, 2, 3]) == [1, 3]
      assert_value search("[::-1]", [0, 1, 2, 3]) == [3, 2, 1, 0]
      assert_value search("[::-2]", [0, 1, 2, 3]) == [3, 1]
      assert_value search("a[:]", %{"a" => [0, 1, 2, 3]}) == [0, 1, 2, 3]
    end

    test "list" do
      assert_value search("[a]", %{"a" => "b", "c" => "d"}) == ["b"]
      assert_value search("[a,c]", %{"a" => "b", "c" => "d"}) == ["b", "d"]
      assert_value search("[a,b,c]", %{"a" => "b", "c" => "d"}) == ["b", nil, "d"]
    end

    test "dict" do
      map = %{"a" => "b", "c" => "d"}
      assert_value search("{one: a, two: b}", map) == %{"one" => "b", "two" => nil}
    end

    test "filter" do
      persons = [%{"name" => "alice"}, %{"name" => "bob"}, nil]
      assert_value search("[?name == 'alice']", persons) == [%{"name" => "alice"}]
    end

    test "call" do
      assert_value search("a(`-1`)", nil) == {:error, :unknown_function}
    end

    test "abs" do
      assert_value search("abs(`-1`)", nil) == 1
      assert_value search("abs()", nil) == {:error, :invalid_arity}
      assert_value search("abs(`1`, `2`)", nil) == {:error, :invalid_arity}
      assert_value search("abs(`true`)", nil) == {:error, :invalid_type}
    end

    test "avg" do
      assert_value search("avg(`[10,20]`)", nil) == 15.0
      assert_value search("avg(`true`)", nil) == {:error, :invalid_type}
      assert_value search("avg(`[10,true,20]`)", nil) == {:error, :invalid_type}
    end

    test "contains" do
      assert_value search("contains(`[10,true,20]`, `10`)", nil) == true
      assert_value search("contains(`[10,true,20]`, `15`)", nil) == false
      assert_value search("contains('alice', 'li')", nil) == true
      assert_value search("contains('alice', 'il')", nil) == false
      assert_value search("contains(`2`, 'il')", nil) == {:error, :invalid_type}
    end

    test "ceil" do
      assert_value search("ceil(`1.5`)", nil) == 2
    end

    test "ends_with" do
      assert_value search("ends_with('alice', 'ce')", nil) == true
      assert_value search("ends_with('alice', 'il')", nil) == false
    end

    test "floor" do
      assert_value search("floor(`1.5`)", nil) == 1
    end

    test "join" do
      assert_value search("join(' ', `[\"hello\", \"world\"]`)", nil) == "hello world"
    end

    test "keys" do
      assert_value search("keys(@)", %{"a" => 1, "b" => 2}) == ["a", "b"]
      assert_value search("keys(@)", %{a: 1, b: 2}) == [:a, :b]
    end

    test "length" do
      assert_value search("length(@)", "alice") == 5
      assert_value search("length(@)", [1, 2, 3]) == 3
      assert_value search("length(@)", %{"a" => 1, "b" => 2}) == 2
    end

    test "map" do
      assert_value search("map(& @ > `1`, @)", [1, 2, 3]) == [false, true, true]
    end

    test "max" do
      assert_value search("max(@)", []) == nil
      assert_value search("max(@)", [1, 3, 2]) == 3
      assert_value search("max(@)", ["alice", "charlie", "bob"]) == "charlie"
    end

    test "max_by" do
      persons = [%{"name" => "alice", "age" => 20}, %{"name" => "bob", "age" => 40}]
      assert_value search("max_by(@, &age).name", persons) == "bob"
    end

    test "min" do
      assert_value search("min(@)", [1, 3, 2]) == 1
      assert_value search("min(@)", ["alice", "charlie", "bob"]) == "alice"
    end

    test "min_by" do
      persons = [%{"name" => "alice", "age" => 20}, %{"name" => "bob", "age" => 40}]
      assert_value search("min_by(@, &age).name", persons) == "alice"
    end

    test "underscore" do
      assert_value JMES.search("keyA", %{"key_a" => true}, underscore: true) == {:ok, true}
      assert_value JMES.search("key_a", %{"key_a" => true}, underscore: true) == {:ok, true}
      assert_value JMES.search("keyA", %{"key_a" => true}, underscore: false) == {:ok, nil}
    end

    defmodule CustomFunctions do
      @behaviour JMES.Functions.Handler
      def call("myfun", _args, _opts) do
        {:ok, 123}
      end
    end

    test "custom functions" do
      assert_value JMES.search("myfun()", %{}, custom_functions: CustomFunctions) == {:ok, 123}
    end
  end

  defp search(expr, data) do
    case JMES.search(expr, data) do
      {:ok, value} -> value
      err -> err
    end
  end
end

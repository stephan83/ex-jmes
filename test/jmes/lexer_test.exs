defmodule JMES.LexerTest do
  use ExUnit.Case

  import AssertValue

  alias JMES.Lexer

  describe "scan/1" do
    test "whitespace" do
      assert_value scan(" \t\n\r") == []
    end

    test "unquoted" do
      assert_value scan("a") == [{:unquoted, 1, "a"}]
      assert_value scan("A") == [{:unquoted, 1, "A"}]
      assert_value scan("_") == [{:unquoted, 1, "_"}]
      assert_value scan("aa") == [{:unquoted, 1, "aa"}]
      assert_value scan("_a") == [{:unquoted, 1, "_a"}]
      assert_value scan("a1") == [{:unquoted, 1, "a1"}]
    end

    test "quoted" do
      assert_value scan(~S{"hello world"}) == [{:quoted, 1, "hello world"}]
      assert_value scan(~S{"\"hello world\""}) == [{:quoted, 1, "\"hello world\""}]
      assert_value scan(~S{"hello\tworld"}) == [{:quoted, 1, "hello\tworld"}]
      assert_value scan(~S{"\uaBA1"}) == [{:quoted, 1, "ꮡ"}]
      assert_value scan(~S{"\uD834\uDD1E"}) == [{:quoted, 1, "𝄞"}]

      assert_value scan(~S{"\uabag"}) ==
                     {:error, {1, :jmes_lexer, {:user, 'invalid escape sequence'}}, 1}
    end

    test "raw" do
      assert_value scan("'raw'") == [{:raw, 1, "raw"}]
      assert_value scan(~S{'raw\n'}) == [{:raw, 1, "raw\\n"}]
      assert_value scan(~S{'\'hello world\''}) == [{:raw, 1, "'hello world'"}]
    end

    test "json" do
      assert_value scan("`true`") == [{:json, 1, "true"}]
      assert_value scan(~S{`"\`hello world\`"`}) == [{:json, 1, "\"`hello world`\""}]
    end

    test "integer" do
      assert_value scan("1") == [{:integer, 1, 1}]
      assert_value scan("-1") == [{:integer, 1, -1}]
    end

    test "tokens" do
      assert scan("(") == [{:"(", 1, '('}]
      assert scan(")") == [{:")", 1, ')'}]
      assert scan("[") == [{:"[", 1, '['}]
      assert scan("]") == [{:"]", 1, ']'}]
      assert scan("[?") == [{:"[?", 1, '[?'}]
      assert scan("{") == [{:"{", 1, '{'}]
      assert scan("}") == [{:"}", 1, '}'}]
      assert scan("*") == [{:*, 1, '*'}]
      assert scan("@") == [{:@, 1, '@'}]
      assert scan("|") == [{:|, 1, '|'}]
      assert scan("||") == [{:||, 1, '||'}]
      assert scan("&&") == [{:&&, 1, '&&'}]
      assert scan("==") == [{:==, 1, '=='}]
      assert scan("!=") == [{:!=, 1, '!='}]
      assert scan("<") == [{:<, 1, '<'}]
      assert scan(">") == [{:>, 1, '>'}]
      assert scan("<=") == [{:<=, 1, '<='}]
      assert scan(">=") == [{:>=, 1, '>='}]
      assert scan("!") == [{:!, 1, '!'}]
      assert scan(".") == [{:., 1, '.'}]
      assert scan(":") == [{:":", 1, ':'}]
      assert scan(",") == [{:",", 1, ','}]
      assert scan("&") == [{:&, 1, '&'}]
    end

    test "invalid" do
      assert_value scan("$") == {:error, {1, :jmes_lexer, {:illegal, '$'}}, 1}
    end
  end

  defp scan(expr) do
    case Lexer.scan(expr) do
      {:ok, tokens, _} -> tokens
      err -> err
    end
  end
end

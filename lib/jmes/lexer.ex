defmodule JMES.Lexer do
  @moduledoc """
  Tokenizes JMESPath expressions.
  """

  @type tokens :: [atom | tuple]
  @type success :: {:ok, tokens, pos_integer}
  @type error :: {atom, any, pos_integer}

  @doc """
  Tokenizes a JMESPath expression.
  """
  @spec scan(String.t()) :: success | error
  def scan(expr) when is_binary(expr) do
    expr |> to_charlist() |> scan()
  end

  @spec scan(charlist) :: success | error
  def scan(expr) do
    :jmes_lexer.string(expr)
  end
end

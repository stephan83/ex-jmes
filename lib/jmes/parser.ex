defmodule JMES.Parser do
  @moduledoc """
  Parses JMESPath expressions.
  """

  alias JMES.Lexer

  @type expr :: String.t() | charlist
  @type ast :: tuple | atom
  @type error :: {:error, any}

  @doc """
  Parse a JMESPath expression into an Abstract Syntax Tree.
  """
  @spec parse(expr) :: {:ok, ast} | error
  def parse(expr) do
    with {:ok, tokens, _} <- Lexer.scan(expr) do
      :jmes_parser.parse(tokens)
    end
  end
end

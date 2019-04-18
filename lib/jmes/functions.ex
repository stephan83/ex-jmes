defmodule JMES.Functions do
  @moduledoc """
  Contains builtin functions.
  """

  # ==============================================================================================
  # abs
  # ==============================================================================================

  @doc """
  Executes a function given a name and a list of arguments.
  """
  @spec call(String.t(), list) :: {:ok, term} | {:error, atom}
  def call("abs", args) when length(args) != 1 do
    {:error, :invalid_arity}
  end

  def call("abs", [value]) when not is_number(value) do
    {:error, :invalid_type}
  end

  def call("abs", [value]) do
    {:ok, abs(value)}
  end

  # ==============================================================================================
  # avg
  # ==============================================================================================

  def call("avg", args) when length(args) != 1 do
    {:error, :invalid_arity}
  end

  def call("avg", [list]) do
    with :ok <- list_of(list, :number) do
      {:ok, Enum.reduce(list, 0, &+/2) / length(list)}
    end
  end

  # ==============================================================================================
  # contains
  # ==============================================================================================

  def call("contains", args) when length(args) != 2 do
    {:error, :invalid_arity}
  end

  def call("contains", [list, value]) when is_list(list) do
    {:ok, value in list}
  end

  def call("contains", [string, value]) when is_binary(value) and is_binary(string) do
    {:ok, String.contains?(string, value)}
  end

  def call("contains", _args) do
    {:error, :invalid_type}
  end

  # ==============================================================================================
  # ceil
  # ==============================================================================================

  def call("ceil", args) when length(args) != 1 do
    {:error, :invalid_arity}
  end

  def call("ceil", [value]) when not is_number(value) do
    {:error, :invalid_type}
  end

  def call("ceil", [value]) do
    {:ok, ceil(value)}
  end

  # ==============================================================================================
  # ends_with
  # ==============================================================================================

  def call("ends_with", args) when length(args) != 2 do
    {:error, :invalid_arity}
  end

  def call("ends_with", [string, suffix]) when not (is_binary(string) and is_binary(suffix)) do
    {:error, :invalid_type}
  end

  def call("ends_with", [string, suffix]) do
    {:ok, String.ends_with?(string, suffix)}
  end

  # ==============================================================================================
  # floor
  # ==============================================================================================

  def call("floor", args) when length(args) != 1 do
    {:error, :invalid_arity}
  end

  def call("floor", [value]) when not is_number(value) do
    {:error, :invalid_type}
  end

  def call("floor", [value]) do
    {:ok, floor(value)}
  end

  # ==============================================================================================
  # join
  # ==============================================================================================

  def call("join", args) when length(args) != 2 do
    {:error, :invalid_arity}
  end

  def call("join", [joiner, _list]) when not is_binary(joiner) do
    {:error, :invalid_type}
  end

  def call("join", [joiner, list]) do
    with :ok <- list_of(list, :string) do
      {:ok, Enum.join(list, joiner)}
    end
  end

  # ==============================================================================================
  # keys
  # ==============================================================================================

  def call("keys", args) when length(args) != 1 do
    {:error, :invalid_arity}
  end

  def call("keys", [value]) when not is_map(value) do
    {:error, :invalid_type}
  end

  def call("keys", [value]) do
    {:ok, Map.keys(value)}
  end

  # ==============================================================================================
  # length
  # ==============================================================================================

  def call("length", args) when length(args) != 1 do
    {:error, :invalid_arity}
  end

  def call("length", [value]) when is_binary(value) do
    {:ok, String.length(value)}
  end

  def call("length", [value]) when is_list(value) do
    {:ok, length(value)}
  end

  def call("length", [value]) when is_map(value) do
    {:ok, length(Map.keys(value))}
  end

  def call("length", _args) do
    {:error, :invalid_type}
  end

  # ==============================================================================================
  # map
  # ==============================================================================================

  def call("map", args) when length(args) != 2 do
    {:error, :invalid_arity}
  end

  def call("map", [expr, _list]) when not is_atom(expr) and not is_tuple(expr) do
    {:error, :invalid_type}
  end

  def call("map", [_expr, list]) when not is_list(list) do
    {:error, :invalid_type}
  end

  def call("map", [expr, list]) do
    List.foldr(list, {:ok, []}, fn
      item, {:ok, list} ->
        case JMES.search(expr, item) do
          {:ok, value} -> {:ok, [value | list]}
          err -> err
        end

      _expr, err ->
        err
    end)
  end

  # ==============================================================================================
  # max
  # ==============================================================================================

  def call("max", args) when length(args) != 1 do
    {:error, :invalid_arity}
  end

  def call("max", [value]) do
    with :ok <- one_of([&list_of(&1, :number), &list_of(&1, :string)], value) do
      {:ok, Enum.max(value, fn -> nil end)}
    end
  end

  # ==============================================================================================
  # max_by
  # ==============================================================================================

  def call("max_by", args) when length(args) != 2 do
    {:error, :invalid_arity}
  end

  def call("max_by", [list, expr]) do
    eject = fn {_item, value} -> value end

    with {:ok, values} <- call("map", [expr, list]),
         :ok <- one_of([&list_of(&1, :number), &list_of(&1, :string)], values),
         {item, _value} <- Enum.max_by(Enum.zip(list, values), eject, fn -> nil end) do
      {:ok, item}
    end
  end

  # ==============================================================================================
  # merge
  # ==============================================================================================

  def call("merge", args) when length(args) < 1 do
    {:error, :invalid_arity}
  end

  def call("merge", args) do
    with :ok <- list_of(args, :map) do
      Enum.reduce(args, {:ok, %{}}, fn curr, {:ok, acc} ->
        {:ok, Enum.into(curr, acc)}
      end)
    end
  end

  # ==============================================================================================
  # min
  # ==============================================================================================

  def call("min", args) when length(args) != 1 do
    {:error, :invalid_arity}
  end

  def call("min", [value]) do
    with :ok <- one_of([&list_of(&1, :number), &list_of(&1, :string)], value) do
      {:ok, Enum.min(value, fn -> nil end)}
    end
  end

  # ==============================================================================================
  # min_by
  # ==============================================================================================

  def call("min_by", args) when length(args) != 2 do
    {:error, :invalid_arity}
  end

  def call("min_by", [list, expr]) do
    eject = fn {_item, value} -> value end

    with {:ok, values} <- call("map", [expr, list]),
         :ok <- one_of([&list_of(&1, :number), &list_of(&1, :string)], values),
         {item, _value} <- Enum.min_by(Enum.zip(list, values), eject, fn -> nil end) do
      {:ok, item}
    end
  end

  # ==============================================================================================
  # not_null
  # ==============================================================================================

  def call("not_null", args) when length(args) < 1 do
    {:error, :invalid_arity}
  end

  def call("not_null", args) do
    {:ok, Enum.find(args, &(&1 != nil))}
  end

  # ==============================================================================================
  # reverse
  # ==============================================================================================

  def call("reverse", args) when length(args) != 1 do
    {:error, :invalid_arity}
  end

  def call("reverse", [value]) when is_binary(value) do
    {:ok, String.reverse(value)}
  end

  def call("reverse", [value]) when is_list(value) do
    {:ok, Enum.reverse(value)}
  end

  def call("reverse", _args) do
    {:error, :invalid_type}
  end

  # ==============================================================================================
  # sort
  # ==============================================================================================

  def call("sort", args) when length(args) != 1 do
    {:error, :invalid_arity}
  end

  def call("sort", [value]) do
    with :ok <- one_of([&list_of(&1, :number), &list_of(&1, :string)], value) do
      {:ok, Enum.sort(value)}
    end
  end

  # ==============================================================================================
  # sort_by
  # ==============================================================================================

  def call("sort_by", args) when length(args) != 2 do
    {:error, :invalid_arity}
  end

  def call("sort_by", [list, expr]) do
    eject_item = fn {item, _value} -> item end
    eject_value = fn {_item, value} -> value end

    with {:ok, values} <- call("map", [expr, list]),
         :ok <- one_of([&list_of(&1, :number), &list_of(&1, :string)], values) do
      items =
        Enum.zip(list, values)
        |> Enum.sort_by(eject_value)
        |> Enum.map(eject_item)

      {:ok, items}
    end
  end

  # ==============================================================================================
  # starts_with
  # ==============================================================================================

  def call("starts_with", args) when length(args) != 2 do
    {:error, :invalid_arity}
  end

  def call("starts_with", [string, suffix]) when not (is_binary(string) and is_binary(suffix)) do
    {:error, :invalid_type}
  end

  def call("starts_with", [string, suffix]) do
    {:ok, String.starts_with?(string, suffix)}
  end

  # ==============================================================================================
  # sum
  # ==============================================================================================

  def call("sum", args) when length(args) != 1 do
    {:error, :invalid_arity}
  end

  def call("sum", [list]) do
    with :ok <- list_of(list, :number) do
      {:ok, Enum.reduce(list, 0, &(&1 + &2))}
    end
  end

  # ==============================================================================================
  # to_array
  # ==============================================================================================

  def call("to_array", args) when length(args) != 1 do
    {:error, :invalid_arity}
  end

  def call("to_array", [value]) when is_list(value) do
    {:ok, value}
  end

  def call("to_array", [value]) when is_nil(value) do
    {:ok, nil}
  end

  def call("to_array", [value]) do
    {:ok, [value]}
  end

  def call("to_array", _args) do
    {:error, :invalid_type}
  end

  # ==============================================================================================
  # to_string
  # ==============================================================================================

  def call("to_string", args) when length(args) != 1 do
    {:error, :invalid_arity}
  end

  def call("to_string", [value]) when is_binary(value) do
    {:ok, value}
  end

  def call("to_string", [value]) do
    Poison.encode(value)
  end

  # ==============================================================================================
  # to_number
  # ==============================================================================================

  def call("to_number", args) when length(args) != 1 do
    {:error, :invalid_arity}
  end

  def call("to_number", [value]) when is_number(value) do
    {:ok, value}
  end

  def call("to_number", [value]) when is_binary(value) do
    case Float.parse(value) do
      {float, _rest} -> {:ok, float}
      :error -> {:ok, nil}
    end
  end

  def call("to_number", _args) do
    {:ok, nil}
  end

  # ==============================================================================================
  # type
  # ==============================================================================================

  def call("type", args) when length(args) != 1 do
    {:error, :invalid_arity}
  end

  def call("type", [value]) when is_number(value) do
    {:ok, "number"}
  end

  def call("type", [value]) when is_binary(value) do
    {:ok, "string"}
  end

  def call("type", [value]) when is_boolean(value) do
    {:ok, "boolean"}
  end

  def call("type", [value]) when is_list(value) do
    {:ok, "array"}
  end

  def call("type", [value]) when is_map(value) do
    {:ok, "object"}
  end

  def call("type", _args) do
    {:ok, "null"}
  end

  # ==============================================================================================
  # values
  # ==============================================================================================

  def call("values", args) when length(args) != 1 do
    {:error, :invalid_arity}
  end

  def call("values", [value]) when not is_map(value) do
    {:error, :invalid_type}
  end

  def call("values", [value]) do
    {:ok, Map.values(value)}
  end

  # ==============================================================================================
  # Fallback
  # ==============================================================================================

  def call(_name, _args) do
    {:error, :unknown_function}
  end

  # ==============================================================================================
  # Helpers
  # ==============================================================================================

  @spec list_of(any, atom) :: :ok | {:error, atom}

  defp list_of(value, _type) when not is_list(value) do
    {:error, :invalid_type}
  end

  defp list_of(value, :number) do
    Enum.reduce_while(value, :ok, fn
      item, _acc when is_number(item) -> {:cont, :ok}
      _item, _acc -> {:halt, {:error, :invalid_type}}
    end)
  end

  defp list_of(value, :string) do
    Enum.reduce_while(value, :ok, fn
      item, _acc when is_binary(item) -> {:cont, :ok}
      _item, _acc -> {:halt, {:error, :invalid_type}}
    end)
  end

  defp list_of(value, :map) do
    Enum.reduce_while(value, :ok, fn
      item, _acc when is_map(item) -> {:cont, :ok}
      _item, _acc -> {:halt, {:error, :invalid_type}}
    end)
  end

  @spec one_of([(any -> :ok | {:error, atom})], any) :: :ok | {:error, atom}
  defp one_of(funs, value) do
    Enum.reduce_while(funs, {:error, :invalid_type}, fn fun, _acc ->
      case apply(fun, [value]) do
        :ok -> {:halt, :ok}
        err -> {:cont, err}
      end
    end)
  end
end

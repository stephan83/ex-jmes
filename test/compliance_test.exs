defmodule JMES.ComplianceTest do
  use ExUnit.Case

  @fixtures_path Path.expand("../priv/compliance", __DIR__)

  files =
    @fixtures_path
    |> File.ls!()
    |> Enum.filter(&String.ends_with?(&1, ".json"))

  files
  |> Enum.map(&Path.join(@fixtures_path, &1))
  |> Enum.map(&File.read!/1)
  |> Enum.map(&Poison.decode!/1)
  |> Enum.zip(files)
  |> Enum.each(fn {tests, file} ->
    describe file do
      Enum.each(tests, fn test ->
        data = Map.fetch!(test, "given")
        data_json = Poison.encode!(data) |> String.slice(0..64)
        cases = Map.fetch!(test, "cases")

        Enum.each(cases, fn tc ->
          expr = Map.fetch!(tc, "expression")
          expected = Map.get(tc, "result")
          error = Map.get(tc, "error")
          title = "search(`#{expr}`, `#{data_json}`)"

          @tag :compliance
          @expr expr
          @data data
          @expected expected
          @error error
          test title do
            if @error do
              case JMES.search(@expr, @data) do
                {:error, _} -> true
                {:error, _, _} -> true
                value -> assert value == nil
              end
            else
              assert JMES.search(@expr, @data) == {:ok, @expected}
            end
          end
        end)
      end)
    end
  end)
end

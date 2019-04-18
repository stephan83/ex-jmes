persons = [%{"name" => "alice", "age" => 20}, %{"name" => "bob", "age" => 40}]
{:ok, ast} = JMES.Parser.parse("max_by(@, & age).name")

Benchee.run(%{
  "search(expr)" => fn ->
    JMES.search("max_by(@, & age).name", persons) == "bob"
  end,
  "search(ast)" => fn ->
    JMES.search(ast, persons) == "bob"
  end
})

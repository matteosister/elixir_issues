defmodule CliTest do
  use ExUnit.Case

  import Issues.CLI, only: [ parse_args: 1,
                             sort_into_ascending_order: 1,
                             convert_to_list_of_hashdicts: 1,
                             get_cell: 3,
                             get_cell: 2,
                             get_max_size: 2 ]

  test ":help returned by option parsing with -h and --help options" do
    assert parse_args(["-h", "anything"]) == :help
    assert parse_args(["--help", "anything"]) == :help
  end

  test "three values returned if three given" do
    assert parse_args(["user", "project", "99"]) == { "user", "project", 99 }
  end

  test "count is defaulted if two values given" do
    assert parse_args(["user", "project"]) == {"user", "project", 4}
  end

  test "sort ascending orders the correct way" do
    result = sort_into_ascending_order(fake_created_at_list(["c", "a", "b"]))
    issues = for issue <- result, do: issue["created_at"]
    assert issues == ~w{a b c}
  end

  defp fake_created_at_list(values) do
    data = for value <- values,
           do: [{"created_at", value}, {"other_data", "xxx"}]
    convert_to_list_of_hashdicts data
  end

  test "get_cell with default pad" do
    assert "a  " == get_cell("a", 3)
    assert "b " == get_cell("b", 2)
  end

  test "get_cell with custom pad" do
    assert "a--" == get_cell("a", 3, ?-)
    assert "b-" == get_cell("b", 2, ?-)
  end

  test "get_max_size" do
    dataStrings = [Enum.into([{"a", "120"}], HashDict.new), Enum.into([{"a", "22"}], HashDict.new)]
    dataInt = [Enum.into([{"a", 120}], HashDict.new), Enum.into([{"a", 22}], HashDict.new)]
    assert 3 == get_max_size dataStrings, "a"
    assert 3 == get_max_size dataInt, "a"
  end
end

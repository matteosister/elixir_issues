defmodule Issues.CLI do
  
  @default_count 4

  @moduledoc """
  Handle the command line parsing and the dispatch to
  the various functions that end up generating a
  table of the last _n_ issues in a github project
  """

  def run(argv) do
    argv
      |> parse_args
      |> process
  end

  @doc """
  `argv` can be -h or --help, which returns :help
  
  Otherwise it is a github user name, project name, and (optionally)
  the number of entires to format.

  Return a tuple od `{ user, project, count }`, or `:help` if help was given
  """
  def parse_args(argv) do
    parse = OptionParser.parse(argv, switches: [help: :boolean], aliases: [h: :help])

    case parse do
      { [help: true], _, _} -> :help
      { _, [user, project, count], _ } -> { user, project, String.to_integer(count) }
      { _, [user, project], _ } -> { user, project, @default_count }
      _ -> :help
    end
  end

  def process(:help) do
    IO.puts """
    usage: issues <user> <project> [count | #{@default_count}]
    """
    System.halt(0)
  end

  def process({user, project, count}) do
    Issues.GithubIssues.fetch(user, project)
    |> decode_response
    |> convert_to_list_of_hashdicts
    |> sort_into_ascending_order
    |> Enum.take(count)
    |> format_to_table
  end

  def decode_response({:ok, body}), do: body
  def decode_response({:error, error}) do
    {_, message} = List.keyfind(error, "message", 0)
    IO.puts "Error fetching from Github: #{ message }"
    System.halt(2)
  end

  def convert_to_list_of_hashdicts(list) do
    list
    |> Enum.map(&Enum.into(&1, HashDict.new))
  end

  def sort_into_ascending_order(list_of_issues) do
    Enum.sort list_of_issues, &(&1["created_at"] <= &2["created_at"])
  end

  #Issues.CLI.process {"matteosister", "GitElephant", 5}

  defp format_to_table(list_of_issues) do
    max_size_number = get_max_size list_of_issues, "number"
    max_size_created_at = get_max_size list_of_issues, "created_at"
    max_size_title = get_max_size list_of_issues, "title"
    IO.puts get_table_header(max_size_number, max_size_created_at, max_size_title)
    IO.puts get_table_divider(max_size_number, max_size_created_at, max_size_title)
    list_of_issues
    |> Enum.map(&get_table_row/1)
    |> Enum.map(&IO.puts/1)
  end

  def get_max_size(list_of_issues, key) do
    sizes = list_of_issues
    |> Enum.reduce([], &(&2 ++ [&1[key]]))
    |> Enum.map &get_size/1
    Enum.max sizes
  end

  def get_size(v) when is_integer(v), do: String.length(Integer.to_string(v))
  def get_size(v) when is_binary(v), do: String.length(v)
  def get_size(v), do: raise "Unable to calculate size of #{v}"

  defp get_table_header(number_size, created_at_size, title_size) do
    "#{ get_cell("#", number_size) } | #{ get_cell("created_at", created_at_size) } | #{ get_cell("title", title_size) }"
  end

  defp get_table_divider(number_size, created_at_size, title_size) do
    "#{get_cell("-", number_size, ?-)}-+-#{get_cell("-", created_at_size, ?-)}-+#{get_cell("-", title_size, ?-)}-"
  end

  defp get_table_row(issue) do
    "#{issue["number"]} | #{issue["created_at"]} | #{issue["title"]}"
  end

  def get_cell(value, size, pad \\ 32) do
    String.ljust(value, size, pad)
  end
end

defmodule PetalBoilerplate.SEOContent.FrontmatterParser do
  @moduledoc """
  Parses committed SEO content with Elixir-map frontmatter.

  Each Markdown file starts with a literal Elixir map and a `---` separator.
  The Markdown body is kept in the parsed attributes so HTML and Markdown
  responses use one editorial source.
  """

  @frontmatter_separator ~r/^---\s*$/m

  @doc """
  Returns the frontmatter attributes and Markdown body for NimblePublisher.
  """
  @spec parse(String.t(), String.t()) :: {map(), String.t()}
  def parse(path, contents) do
    case Regex.split(@frontmatter_separator, contents, parts: 2) do
      [frontmatter, body] ->
        markdown = String.trim_leading(body)

        attrs =
          path
          |> parse_frontmatter!(frontmatter)
          |> Map.put(:markdown, markdown)

        {attrs, markdown}

      [_only_body] ->
        raise ArgumentError,
              "Missing frontmatter in SEO content file #{inspect(path)}. " <>
                "Expected an Elixir map followed by a line with `---`."
    end
  end

  defp parse_frontmatter!(path, frontmatter) do
    frontmatter
    |> String.trim()
    |> Code.string_to_quoted(file: path)
    |> case do
      {:ok, {:%{}, _metadata, _pairs} = ast} ->
        ensure_literal_values!(path, ast)
        evaluate_map!(path, ast)

      {:ok, _other} ->
        raise ArgumentError,
              "Frontmatter in #{inspect(path)} must be an Elixir map literal"

      {:error, {line, error, token}} ->
        raise ArgumentError,
              "Invalid frontmatter in #{inspect(path)} at line #{line}: " <>
                "#{error}#{token}"
    end
  end

  defp ensure_literal_values!(path, ast) do
    unless literal_ast?(ast) do
      raise ArgumentError,
            "Frontmatter in #{inspect(path)} must contain literal values only"
    end
  end

  defp literal_ast?({:%{}, _metadata, pairs}) do
    Enum.all?(pairs, fn {key, value} -> literal_ast?(key) and literal_ast?(value) end)
  end

  defp literal_ast?({:{}, _metadata, values}), do: Enum.all?(values, &literal_ast?/1)

  defp literal_ast?(pair) when is_tuple(pair) and tuple_size(pair) == 2 do
    pair
    |> Tuple.to_list()
    |> Enum.all?(&literal_ast?/1)
  end

  defp literal_ast?(values) when is_list(values), do: Enum.all?(values, &literal_ast?/1)
  defp literal_ast?(value) when is_atom(value) or is_binary(value) or is_number(value), do: true
  defp literal_ast?(_value), do: false

  defp evaluate_map!(path, ast) do
    {attrs, _bindings} = Code.eval_quoted(ast)
    attrs
  rescue
    error ->
      reraise ArgumentError,
              [
                message:
                  "Failed to evaluate frontmatter in #{inspect(path)}: " <>
                    Exception.message(error)
              ],
              __STACKTRACE__
  end
end

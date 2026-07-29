defmodule PetalBoilerplateWeb.Plugs.LLMAcceptCompat do
  @moduledoc """
  Makes Markdown requests compatible with the browser accepts plug.
  """

  import Plug.Conn

  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    accept =
      conn
      |> get_req_header("accept")
      |> Enum.join(", ")
      |> String.trim()

    if markdown_requested?(accept) and not html_compatible?(accept) do
      conn
      |> delete_req_header("accept")
      |> put_req_header("accept", accept <> ", text/html;q=0.9")
    else
      conn
    end
  end

  defp markdown_requested?(accept), do: String.contains?(String.downcase(accept), "text/markdown")

  defp html_compatible?(accept) do
    value = String.downcase(accept)
    String.contains?(value, "text/html") or String.contains?(value, "*/*")
  end
end

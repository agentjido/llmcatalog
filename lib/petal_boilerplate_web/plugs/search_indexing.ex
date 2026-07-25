defmodule PetalBoilerplateWeb.Plugs.SearchIndexing do
  @moduledoc """
  Blocks indexing when the runtime environment disables public indexing.
  """

  import Plug.Conn

  alias PetalBoilerplateWeb.SEO

  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, _opts) do
    if SEO.indexing_enabled?() do
      conn
    else
      register_before_send(conn, &put_noindex_header/1)
    end
  end

  defp put_noindex_header(conn) do
    directives =
      conn
      |> get_resp_header("x-robots-tag")
      |> Enum.flat_map(&String.split(&1, ","))
      |> Enum.map(&String.trim/1)
      |> Kernel.++(["noindex", "nofollow"])
      |> Enum.reject(&(&1 == ""))
      |> Enum.uniq()

    put_resp_header(conn, "x-robots-tag", Enum.join(directives, ", "))
  end
end

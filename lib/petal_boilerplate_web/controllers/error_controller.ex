defmodule PetalBoilerplateWeb.ErrorController do
  use PetalBoilerplateWeb, :controller

  alias PetalBoilerplateWeb.ErrorHTML

  def not_found(conn, _params) do
    conn =
      conn
      |> put_resp_header("vary", "Accept")
      |> put_resp_header("x-robots-tag", "noindex, nofollow")

    if markdown_requested?(conn) do
      conn
      |> put_resp_content_type("text/markdown", "utf-8")
      |> send_resp(404, ErrorHTML.not_found_markdown(conn.request_path))
    else
      conn
      |> put_resp_content_type("text/html", "utf-8")
      |> send_resp(404, ErrorHTML.not_found_html())
    end
  end

  defp markdown_requested?(conn) do
    String.ends_with?(conn.request_path, ".md") or
      Enum.any?(get_req_header(conn, "accept"), fn value ->
        String.contains?(String.downcase(value), "text/markdown")
      end)
  end
end

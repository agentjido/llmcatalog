defmodule PetalBoilerplateWeb.ErrorController do
  use PetalBoilerplateWeb, :controller

  alias PetalBoilerplateWeb.ErrorHTML

  def not_found(conn, _params) do
    conn
    |> put_status(:not_found)
    |> put_resp_content_type("text/html", "utf-8")
    |> put_resp_header("x-robots-tag", "noindex, nofollow")
    |> send_resp(404, ErrorHTML.not_found_html())
  end
end

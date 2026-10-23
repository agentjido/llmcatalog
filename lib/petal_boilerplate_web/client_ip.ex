defmodule PetalBoilerplateWeb.ClientIP do
  @moduledoc """
  Resolves the client IP through the configured trusted proxy.

  Fly sets `Fly-Client-IP` to its direct client. When Cloudflare is in
  front of Fly, that value is a Cloudflare edge IP. In that case, this
  module uses Cloudflare's `CF-Connecting-IP` value only after it verifies
  that the Fly client belongs to a published Cloudflare network.
  """

  import Bitwise
  import Plug.Conn, only: [get_req_header: 2]

  # Source: https://www.cloudflare.com/ips/
  @cloudflare_cidrs [
    "173.245.48.0/20",
    "103.21.244.0/22",
    "103.22.200.0/22",
    "103.31.4.0/22",
    "141.101.64.0/18",
    "108.162.192.0/18",
    "190.93.240.0/20",
    "188.114.96.0/20",
    "197.234.240.0/22",
    "198.41.128.0/17",
    "162.158.0.0/15",
    "104.16.0.0/13",
    "104.24.0.0/14",
    "172.64.0.0/13",
    "131.0.72.0/22",
    "2400:cb00::/32",
    "2606:4700::/32",
    "2803:f800::/32",
    "2405:b500::/32",
    "2405:8100::/32",
    "2a06:98c0::/29",
    "2c0f:f248::/32"
  ]

  @cloudflare_networks Enum.map(@cloudflare_cidrs, fn cidr ->
                         [address, prefix] = String.split(cidr, "/", parts: 2)
                         {:ok, parsed_address} = :inet.parse_address(String.to_charlist(address))
                         bits = if tuple_size(parsed_address) == 4, do: 32, else: 128
                         segment_bits = div(bits, tuple_size(parsed_address))

                         address_integer =
                           Enum.reduce(Tuple.to_list(parsed_address), 0, fn segment, acc ->
                             acc <<< segment_bits ||| segment
                           end)

                         {address_integer, String.to_integer(prefix), bits}
                       end)

  @type trusted_header :: String.t() | nil

  @doc "Returns the normalized client IP for rate limits and trusted proxies."
  @spec resolve(Plug.Conn.t(), trusted_header()) :: String.t()
  def resolve(conn, trusted_header \\ configured_trusted_header()) do
    conn
    |> trusted_ip(trusted_header)
    |> case do
      nil -> conn.remote_ip
      ip -> ip
    end
    |> format_ip()
  end

  defp trusted_ip(_conn, nil), do: nil

  defp trusted_ip(conn, trusted_header) when is_binary(trusted_header) do
    trusted_header = String.downcase(trusted_header)

    case single_header_ip(conn, trusted_header) do
      nil ->
        nil

      fly_ip when trusted_header == "fly-client-ip" ->
        cloudflare_visitor_ip(conn, fly_ip) || fly_ip

      trusted_ip ->
        trusted_ip
    end
  end

  defp trusted_ip(_conn, _trusted_header), do: nil

  defp cloudflare_visitor_ip(conn, fly_ip) do
    if cloudflare_ip?(fly_ip) do
      single_header_ip(conn, "cf-connecting-ip")
    end
  end

  defp cloudflare_ip?(ip) when is_tuple(ip) do
    bits = address_bits(ip)
    address = address_to_integer(ip)

    Enum.any?(@cloudflare_networks, fn
      {network, prefix, ^bits} ->
        shift = bits - prefix
        address >>> shift == network >>> shift

      _other_family ->
        false
    end)
  end

  defp cloudflare_ip?(_ip), do: false

  defp single_header_ip(conn, name) do
    case get_req_header(conn, name) do
      [value] -> parse_ip(value)
      _missing_or_ambiguous -> nil
    end
  end

  defp parse_ip(value) when is_binary(value) do
    value = String.trim(value)

    case :inet.parse_address(String.to_charlist(value)) do
      {:ok, ip} -> ip
      {:error, _reason} -> nil
    end
  end

  defp parse_ip(_value), do: nil

  defp configured_trusted_header do
    Application.get_env(:petal_boilerplate, :trusted_client_ip_header)
  end

  defp address_bits(ip) when tuple_size(ip) == 4, do: 32
  defp address_bits(ip) when tuple_size(ip) == 8, do: 128

  defp address_to_integer(ip) do
    segment_bits = div(address_bits(ip), tuple_size(ip))

    Enum.reduce(Tuple.to_list(ip), 0, fn segment, acc ->
      acc <<< segment_bits ||| segment
    end)
  end

  defp format_ip(ip) when is_tuple(ip) do
    ip
    |> :inet.ntoa()
    |> to_string()
  end

  defp format_ip(_ip), do: "unknown"
end

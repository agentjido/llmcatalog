defmodule PetalBoilerplateWeb.PublicRoutes do
  @moduledoc """
  Builds canonical public paths and absolute URLs.
  """

  alias PetalBoilerplate.Catalog
  alias PetalBoilerplateWeb.Endpoint

  @spec absolute(String.t()) :: String.t()
  def absolute(path) when is_binary(path) do
    Endpoint.url() <> normalize_path(path)
  end

  @spec normalize_path(String.t()) :: String.t()
  def normalize_path(""), do: "/"
  def normalize_path("/"), do: "/"

  def normalize_path(path) when is_binary(path) do
    path
    |> ensure_leading_slash()
    |> String.trim_trailing("/")
  end

  @spec model_path(map() | atom() | String.t(), String.t() | nil) :: String.t()
  def model_path(model, model_id \\ nil)

  def model_path(%{} = model, nil) do
    model_path(model.provider, Map.get(model, :model_id) || model.id)
  end

  def model_path(provider, model_id) when is_binary(model_id) do
    encoded_provider = provider |> to_string() |> encode_segment()

    encoded_model_id =
      model_id
      |> String.split("/")
      |> Enum.map_join("/", &encode_segment/1)

    "/models/#{encoded_provider}/#{encoded_model_id}"
  end

  @spec model_markdown_path(map() | atom() | String.t(), String.t() | nil) :: String.t()
  def model_markdown_path(model, model_id \\ nil)

  def model_markdown_path(%{} = model, nil) do
    model_markdown_path(model.provider, Map.get(model, :model_id) || model.id)
  end

  def model_markdown_path(provider, model_id) do
    model_path(provider, model_id) <> ".md"
  end

  @spec model_og_path(map() | atom() | String.t(), String.t() | nil) :: String.t()
  def model_og_path(model, model_id \\ nil)

  def model_og_path(%{} = model, nil) do
    model_og_path(model.provider, Map.get(model, :model_id) || model.id)
  end

  def model_og_path(provider, model_id) do
    encoded_provider = provider |> to_string() |> encode_segment()

    encoded_model_id =
      model_id
      |> String.split("/")
      |> Enum.map_join("/", &encode_segment/1)

    "/og/model/#{encoded_provider}/#{encoded_model_id}.png"
  end

  @spec markdown_path(String.t()) :: String.t()
  def markdown_path(path) do
    case normalize_path(path) do
      "/" -> "/index.md"
      normalized -> normalized <> ".md"
    end
  end

  @spec model_from_path(String.t()) :: {:ok, map()} | :error
  def model_from_path("/models/" <> rest) do
    with [provider, encoded_model_id] <- String.split(rest, "/", parts: 2),
         true <- provider != "" and encoded_model_id != "",
         decoded_provider <- URI.decode(provider),
         decoded_model_id <- decode_model_id(encoded_model_id),
         %{} = model <- Catalog.get_model(decoded_provider, decoded_model_id) do
      {:ok, model}
    else
      _ -> :error
    end
  end

  def model_from_path(_path), do: :error

  defp decode_model_id(encoded_model_id) do
    encoded_model_id
    |> String.split("/")
    |> Enum.map_join("/", &URI.decode/1)
  end

  defp encode_segment(value), do: URI.encode(to_string(value))

  defp ensure_leading_slash("/" <> _rest = path), do: path
  defp ensure_leading_slash(path), do: "/" <> path
end

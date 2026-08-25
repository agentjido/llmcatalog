defmodule PetalBoilerplate.CatalogTest do
  use ExUnit.Case, async: false

  alias PetalBoilerplate.Catalog
  alias PetalBoilerplate.Catalog.Trending

  defmodule HistoryStub do
    def available?, do: true
    def meta, do: {:ok, %{}}
    def timeline(_provider, _model_id, _limit), do: {:ok, []}

    def recent(_limit) do
      {:ok, Application.get_env(:petal_boilerplate, :catalog_test_recent_events, [])}
    end
  end

  setup do
    original_history_module = Application.get_env(:petal_boilerplate, :history_module)
    original_recent_events = Application.get_env(:petal_boilerplate, :catalog_test_recent_events)

    Trending.reset()
    Catalog.refresh_cache()

    on_exit(fn ->
      restore_env(:history_module, original_history_module)
      restore_env(:catalog_test_recent_events, original_recent_events)
      Trending.reset()
      Catalog.refresh_cache()
    end)

    :ok
  end

  test "list_all_models backfills history metadata for a stale cache" do
    [target_model | _] = Catalog.list_all_models() |> Enum.take(3)

    captured_at =
      DateTime.utc_now()
      |> DateTime.add(-2 * 86_400, :second)
      |> DateTime.truncate(:second)
      |> DateTime.to_iso8601()

    stale_models =
      Catalog.list_all_models()
      |> Enum.take(3)
      |> Enum.map(fn model ->
        model
        |> Map.put(:__last_changed_at, nil)
        |> Map.put(:__last_changed_epoch, nil)
      end)

    Application.put_env(:petal_boilerplate, :history_module, HistoryStub)

    Application.put_env(:petal_boilerplate, :catalog_test_recent_events, [
      %{
        "model_key" => "#{target_model.provider}:#{target_model.model_id}",
        "captured_at" => captured_at,
        "type" => "changed",
        "changes" => [%{"path" => "limits.context"}]
      }
    ])

    :persistent_term.put({Catalog, :models}, stale_models)
    :persistent_term.put({Catalog, :model_count}, length(stale_models))

    refreshed_model =
      Catalog.list_all_models()
      |> Enum.find(fn model ->
        model.provider == target_model.provider and model.model_id == target_model.model_id
      end)

    assert refreshed_model.__last_changed_at == captured_at
    assert is_integer(refreshed_model.__last_changed_epoch)
  end

  test "direct lookup returns models by provider/model_id and dom id" do
    model = Catalog.list_all_models() |> List.first()
    model_dom_id = model.id
    model_id = model.model_id

    assert %{id: ^model_dom_id} = Catalog.get_model(to_string(model.provider), model_id)
    assert %{model_id: ^model_id} = Catalog.get_model_by_dom_id(model_dom_id)
  end

  test "analytics search values use an exact catalog allowlist" do
    provider = Catalog.list_providers() |> List.first()
    model = Catalog.list_all_models() |> List.first()

    assert Catalog.analytics_search_value("  #{String.upcase(provider.name)}  ") ==
             "provider:#{provider.name}"

    assert Catalog.analytics_search_value(String.upcase(model.name)) == "model:#{model.name}"
    assert Catalog.analytics_search_value(model.model_id) == "model:#{model.name}"
    assert Catalog.analytics_search_value("private project launch") == "other"
    assert Catalog.analytics_search_value("  ") == "none"
  end

  test "query_models matches list_models plus paginate" do
    filters = Catalog.default_filters()
    sort = %{by: :recently_changed, dir: :desc}

    expected =
      Catalog.list_all_models()
      |> Catalog.list_models(filters, sort)
      |> Catalog.paginate(2)

    assert Catalog.query_models(filters, sort, 2) == expected
  end

  test "recently changed sort prioritizes recently changed models" do
    older = build_model("older", [:text], [:text]) |> Map.put(:__last_changed_epoch, 100)
    newer = build_model("newer", [:text], [:text]) |> Map.put(:__last_changed_epoch, 200)
    unchanged = build_model("unchanged", [:text], [:text]) |> Map.put(:__last_changed_epoch, nil)

    result =
      Catalog.list_models(
        [older, unchanged, newer],
        Catalog.default_filters(),
        %{by: :recently_changed, dir: :desc}
      )

    assert Enum.map(result, & &1.id) == ["newer", "older", "unchanged"]
  end

  test "trending sort combines usage, intelligence, and a release boost" do
    Trending.put_snapshot(%{
      popular: ["openai/gpt-established", "x-ai/grok-new"],
      intelligence: ["x-ai/grok-new", "openai/gpt-established"]
    })

    established = build_model("gpt-established", [:text], [:text])

    new_model =
      build_model("grok-new", [:text], [:text])
      |> Map.merge(%{
        provider: :xai,
        __provider_str: "xai",
        release_date: Date.utc_today() |> Date.to_iso8601()
      })

    result =
      Catalog.list_models(
        [established, new_model],
        Catalog.default_filters(),
        Catalog.default_sort()
      )

    assert Enum.map(result, & &1.model_id) == ["grok-new", "gpt-established"]
  end

  test "trending sort keeps the first-party route before a duplicate broker route" do
    Trending.put_snapshot(%{popular: ["x-ai/grok-4.6"]})

    official =
      build_model("grok-4.6", [:text], [:text])
      |> Map.merge(%{provider: :xai, __provider_str: "xai"})

    broker =
      build_model("x-ai/grok-4.6", [:text], [:text])
      |> Map.merge(%{provider: :broker, __provider_str: "broker"})

    result =
      Catalog.list_models([broker, official], Catalog.default_filters(), Catalog.default_sort())

    assert Enum.map(result, & &1.provider) == [:xai, :broker]
  end

  test "popular and newest sorts use their named data sources" do
    Trending.put_snapshot(%{popular: ["test-provider/older", "test-provider/newer"]})

    older =
      build_model("older", [:text], [:text])
      |> Map.put(:release_date, "2026-01-01")

    newer =
      build_model("newer", [:text], [:text])
      |> Map.put(:release_date, "2026-08-01")

    assert ["older", "newer"] ==
             [newer, older]
             |> Catalog.list_models(Catalog.default_filters(), %{by: :popular, dir: :desc})
             |> ids()

    assert ["newer", "older"] ==
             [older, newer]
             |> Catalog.list_models(Catalog.default_filters(), %{by: :newest, dir: :desc})
             |> ids()
  end

  test "list_models filters by required input and output modalities" do
    filters = %{
      Catalog.default_filters()
      | modalities_in: MapSet.new([:image, :audio]),
        modalities_out: MapSet.new([:audio])
    }

    models = [
      build_model("text-only", [:text], [:text]),
      build_model("image-to-text", [:text, :image], [:text]),
      build_model("multimodal-audio", [:text, :image, :audio], [:text, :audio])
    ]

    result = Catalog.list_models(models, filters, Catalog.default_sort())

    assert Enum.map(result, & &1.id) == ["multimodal-audio"]
  end

  test "enriched catalog exposes architecture and model size metadata" do
    models = Catalog.list_all_models()

    assert Enum.all?(models, &(&1.__architecture in [:dense, :moe, :unknown]))
    assert Enum.any?(models, &(&1.__architecture == :dense))
    assert Enum.any?(models, &(&1.__architecture == :moe))
    assert Enum.any?(models, &is_number(&1.__total_parameters))
    assert Enum.any?(models, &is_number(&1.__active_parameters))
    assert Enum.any?(models, &is_number(&1.__minimum_ram_gb))
    assert Enum.any?(models, &is_number(&1.__minimum_vram_gb))
  end

  test "list_models filters by architecture" do
    models = [
      build_model("dense", [:text], [:text]) |> Map.put(:__architecture, :dense),
      build_model("moe", [:text], [:text]) |> Map.put(:__architecture, :moe),
      build_model("unknown", [:text], [:text])
    ]

    filters = %{Catalog.default_filters() | architecture: :moe}
    assert models |> Catalog.list_models(filters, Catalog.default_sort()) |> ids() == ["moe"]

    filters = %{filters | architecture: :unknown}
    assert models |> Catalog.list_models(filters, Catalog.default_sort()) |> ids() == ["unknown"]
  end

  test "model size sorts keep missing values last in both directions" do
    for {sort_field, metadata_field} <- [
          total_parameters: :__total_parameters,
          active_parameters: :__active_parameters,
          minimum_ram_gb: :__minimum_ram_gb,
          minimum_vram_gb: :__minimum_vram_gb
        ] do
      models = [
        build_model("missing", [:text], [:text]),
        build_model("small", [:text], [:text]) |> Map.put(metadata_field, 2),
        build_model("large", [:text], [:text]) |> Map.put(metadata_field, 10)
      ]

      assert models
             |> Catalog.list_models(Catalog.default_filters(), %{by: sort_field, dir: :asc})
             |> ids() == ["small", "large", "missing"]

      assert models
             |> Catalog.list_models(Catalog.default_filters(), %{by: sort_field, dir: :desc})
             |> ids() == ["large", "small", "missing"]
    end
  end

  defp restore_env(key, nil), do: Application.delete_env(:petal_boilerplate, key)
  defp restore_env(key, value), do: Application.put_env(:petal_boilerplate, key, value)
  defp ids(models), do: Enum.map(models, & &1.id)

  defp build_model(id, input_modalities, output_modalities) do
    %{
      id: id,
      model_id: id,
      model: id,
      name: id,
      provider: :test_provider,
      deprecated: false,
      catalog_only: false,
      release_date: nil,
      __provider_str: "test_provider",
      __search: id,
      __allowed?: true,
      __caps: MapSet.new(),
      __in: MapSet.new(input_modalities),
      __out: MapSet.new(output_modalities),
      __architecture: :unknown,
      __context: 0,
      __output: 0,
      __cost_in: 0.0,
      __cost_out: 0.0,
      __total_parameters: nil,
      __active_parameters: nil,
      __minimum_ram_gb: nil,
      __minimum_vram_gb: nil
    }
  end
end

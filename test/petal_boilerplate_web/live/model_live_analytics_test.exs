defmodule PetalBoilerplateWeb.ModelLiveAnalyticsTest do
  use PetalBoilerplateWeb.ConnCase, async: false

  alias PetalBoilerplate.Catalog

  setup do
    original_value = Application.get_env(:petal_boilerplate, :enable_analytics)
    Application.put_env(:petal_boilerplate, :enable_analytics, true)

    on_exit(fn ->
      Application.put_env(:petal_boilerplate, :enable_analytics, original_value)
    end)

    :ok
  end

  test "tracks a model search with the result and filter state", %{conn: conn} do
    model = Catalog.list_all_models() |> List.first()
    expected_query = "model:#{model.name}"
    {:ok, view, _html} = live(conn, "/")

    render_change(view, "filter", %{"_target" => ["search"], "search" => model.name})

    assert_push_event view, "plausible-event", %{
      name: "Model Search",
      props: %{
        action: "search",
        query: ^expected_query,
        providers: "none",
        provider_count: 0,
        capabilities: "none",
        input_modalities: "none",
        output_modalities: "none",
        changed_within_days: "none",
        min_context: "none",
        min_output: "none",
        max_input_cost: "none",
        max_output_cost: "none",
        show_deprecated: false,
        allowed_only: true,
        sort_by: "trending",
        sort_direction: "desc",
        result_count: result_count,
        active_filter_count: 1
      }
    }

    assert is_integer(result_count)
    assert result_count > 0
  end

  test "tracks a filter change with the active provider", %{conn: conn} do
    provider_id = first_provider_id()
    {:ok, view, _html} = live(conn, "/?q=gpt")

    render_click(view, "toggle_provider", %{"id" => provider_id})

    assert_push_event view, "plausible-event", %{
      name: "Model Filter",
      props: %{
        action: "providers",
        query: "other",
        providers: ^provider_id,
        result_count: result_count,
        active_filter_count: 2
      }
    }

    assert is_integer(result_count)
  end

  test "tracks a model view for future local popularity ranks", %{conn: conn} do
    model =
      Catalog.query_models(Catalog.default_filters(), Catalog.default_sort(), 1)
      |> elem(0)
      |> hd()

    {:ok, view, _html} = live(conn, "/")

    render_click(view, "show_model", %{"id" => model.id})

    assert_push_event view, "plausible-event", %{
      name: "Model View",
      props: %{provider: provider, model_id: model_id}
    }

    assert provider == to_string(model.provider)
    assert model_id == model.model_id
  end

  test "does not send search text to analytics", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/")

    render_change(view, "filter", %{
      "_target" => ["search"],
      "search" => "person@example.com"
    })

    assert_push_event view, "plausible-event", %{
      name: "Model Search",
      props: %{query: "other"}
    }
  end

  test "sends a canonical provider for an exact allowlisted search", %{conn: conn} do
    provider = Catalog.list_providers() |> List.first()
    expected_query = "provider:#{provider.name}"
    {:ok, view, _html} = live(conn, "/")

    render_change(view, "filter", %{
      "_target" => ["search"],
      "search" => String.upcase(provider.name)
    })

    assert_push_event view, "plausible-event", %{
      name: "Model Search",
      props: %{query: ^expected_query}
    }
  end

  test "does not track a cleared search", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/?q=gpt")

    render_click(view, "clear_search", %{})

    refute_push_event view, "plausible-event", %{}
  end

  test "does not push analytics events when analytics are disabled", %{conn: conn} do
    Application.put_env(:petal_boilerplate, :enable_analytics, false)
    {:ok, view, _html} = live(conn, "/")

    render_change(view, "filter", %{"_target" => ["search"], "search" => "claude"})

    refute_push_event view, "plausible-event", %{}
  end

  defp first_provider_id do
    Catalog.list_providers()
    |> List.first()
    |> Map.fetch!(:id)
    |> to_string()
  end
end

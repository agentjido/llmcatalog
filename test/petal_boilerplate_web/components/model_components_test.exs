defmodule PetalBoilerplateWeb.ModelComponentsTest do
  use PetalBoilerplateWeb.ConnCase, async: true

  alias PetalBoilerplateWeb.ModelComponents

  test "header only renders search clear button when search has a value" do
    active_html = render_component(&ModelComponents.header/1, search_value: "gpt")
    empty_html = render_component(&ModelComponents.header/1, search_value: "")

    assert active_html =~ ~s(aria-label="Clear search")
    refute empty_html =~ ~s(aria-label="Clear search")
  end

  test "header links to developer resources and the model metadata issue form" do
    html = render_component(&ModelComponents.header/1, search_value: "")

    assert html =~ ~s(nav aria-label="Site navigation")
    assert html =~ ~s(href="https://jidokahq.com/")
    assert html =~ ~s(href="https://hex.pm/packages/llm_db")

    assert html
           |> Floki.parse_fragment!()
           |> Floki.find(~s(a[href="https://hex.pm/packages/llm_db"]))
           |> Floki.text()
           |> String.trim() == "v#{Application.spec(:llm_db, :vsn)}"

    assert html =~ ~s(aria-label="View llmdb on GitHub")
    assert html =~ ~s(href="https://jido.run/discord")
    assert html =~ ~s(aria-label="Join Discord")
    assert html =~ ~s(aria-label="Change color theme")
    assert html =~ "Report incorrect model data"
    assert html =~ "template=model_metadata.yml"
    assert html =~ ~s(href="/developers")
    assert html =~ ~s(href="/openapi.json")
    assert html =~ ~s(href="/contact")
    assert html =~ "www.npmjs.com/package/@agentjido/llmdb"
  end

  test "model detail modal renders proposed advanced model metadata" do
    html =
      render_component(&ModelComponents.model_detail_modal/1,
        model: advanced_model(),
        history_events: [],
        history_meta: %{},
        history_available: false,
        history_api_url: nil
      )

    assert html =~ "Claude Fable 5"
    assert html =~ "Max Input"
    assert html =~ "1,000,000 tokens"
    assert html =~ "Reasoning Metadata"
    assert html =~ "low, medium, high, xhigh, max"
    assert html =~ "Default: medium"
    assert html =~ "adaptive"
    assert html =~ "Advanced Capabilities"
    assert html =~ "Code Execution"
    assert html =~ "clear thinking, compact"
    assert html =~ "Pricing Components"
    assert html =~ "token.input.batch"
    assert html =~ "$5.00 / 1M tokens"
    assert html =~ "api: batch"
    assert html =~ "provider_docs"
    assert html =~ "Architecture"
    assert html =~ "Dense"
    assert html =~ "Total Parameters"
    assert html =~ "70B"
    assert html =~ "Minimum RAM"
    assert html =~ "42.5 GB"
    assert html =~ "See incorrect model data?"
    assert html =~ "Submit Fix on GitHub"
    assert html =~ "model-id=claude-fable-5"
    assert html =~ "provider=Anthropic"
  end

  test "comparison modal renders advanced capability and input limit columns" do
    html =
      render_component(&ModelComponents.comparison_modal/1,
        is_open: true,
        models: [advanced_model()],
        on_remove: "remove_from_comparison",
        on_clear: "clear_comparison",
        on_close: "close_comparison"
      )

    assert html =~ "Max Input"
    assert html =~ "Batch"
    assert html =~ "Cite"
    assert html =~ "Code"
    assert html =~ "Ctx"
    assert html =~ "Architecture"
    assert html =~ "Total Parameters"
    assert html =~ "Minimum VRAM"
  end

  test "model table uses clear text summaries for dense model data" do
    html =
      render_component(&ModelComponents.model_table/1,
        models: [advanced_model()],
        sort: %{by: :name, dir: :asc},
        total: 1,
        selected_ids: MapSet.new(),
        can_add_more: true
      )

    assert html =~ "Modalities"
    assert html =~ "Capabilities"
    assert html =~ ~s(aria-label="Input: Text; output: Text")
    assert html =~ "Reasoning, Tools, Batch, Code, JSON"
    assert html =~ "Input / output price"
    assert html =~ "$10.00 / $50.00"
    assert html =~ "1M"
  end

  defp advanced_model do
    %{
      id: "model-test",
      model_id: "claude-fable-5",
      provider: :anthropic,
      name: "Claude Fable 5",
      family: "claude",
      __architecture: :dense,
      __total_parameters: 70_000_000_000,
      __active_parameters: nil,
      __minimum_ram_gb: 42.5,
      __minimum_vram_gb: 38.0,
      __last_changed_at: "2026-08-17T00:00:00Z",
      deprecated: false,
      lifecycle: %{"status" => "active"},
      modalities: %{"input" => [:text], "output" => [:text]},
      limits: %{"context" => 1_000_000, "input" => 1_000_000, "output" => 128_000},
      cost: %{"input" => 10.0, "output" => 50.0, "cache_read" => 1.0},
      capabilities: %{
        "chat" => true,
        "tools" => %{"enabled" => true},
        "json" => %{"schema" => true},
        "reasoning" => %{
          "enabled" => true,
          "effort" => %{
            "supported" => true,
            "values" => ["low", "medium", "high", "xhigh", "max"],
            "default" => "medium"
          },
          "thinking" => %{
            "types" => ["adaptive"],
            "default_type" => "adaptive"
          },
          "token_budget" => %{"min" => 1_024, "max" => 128_000}
        },
        "batch" => %{"supported" => true},
        "citations" => %{"supported" => true},
        "code_execution" => %{"supported" => true},
        "context_management" => %{
          "supported" => true,
          "features" => ["clear_thinking", "compact"]
        }
      },
      pricing: %{
        "components" => [
          %{
            "id" => "token.input.batch",
            "kind" => "token",
            "unit" => "token",
            "per" => 1_000_000,
            "rate" => 5.0,
            "applies_when" => %{"api" => "batch"},
            "source" => "provider_docs"
          }
        ]
      }
    }
  end
end

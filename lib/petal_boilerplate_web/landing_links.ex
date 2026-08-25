defmodule PetalBoilerplateWeb.LandingLinks do
  @moduledoc """
  Defines the curated internal-link graph for catalog landing pages.

  The LLM models list and AI model rankings pages are hubs. Other pages are
  spokes with links to both hubs and to closely related spokes.
  """

  use PetalBoilerplateWeb, :html

  alias PetalBoilerplateWeb.PublicRoutes

  @targets %{
    "/llm-models" => %{
      breadcrumb_label: "LLM Models List",
      category: "Model directory",
      label: "Browse the full LLM models list",
      description:
        "See active text-generation identities with providers, context, capabilities, and prices."
    },
    "/rankings/ai-models" => %{
      breadcrumb_label: "AI Model Rankings",
      category: "Ranking hub",
      label: "Compare objective AI model rankings",
      description:
        "Review separate lists for zero and paid token prices, context size, and catalog freshness."
    },
    "/rankings/cheapest-llm-api" => %{
      breadcrumb_label: "Cheapest LLM APIs",
      category: "Price comparison",
      label: "Compare the cheapest LLM APIs",
      description:
        "Order paid text-generation offers by known input-token price and check output cost."
    },
    "/rankings/free-llm-api" => %{
      breadcrumb_label: "Zero-Price LLM APIs",
      category: "Price availability",
      label: "Check zero-price LLM API offers",
      description:
        "Find active text offers with $0 catalog input and output token prices, with clear limits on what zero price means."
    },
    "/models/vision" => %{
      breadcrumb_label: "Vision LLM Models",
      category: "Input capability",
      label: "Browse vision LLM models",
      description: "Find active text models that accept image input and return text."
    },
    "/models/tool-calling" => %{
      breadcrumb_label: "Tool-Calling LLM Models",
      category: "Agent capability",
      label: "Find tool-calling LLM models",
      description: "Compare active text models with explicit tools capability metadata."
    },
    "/models/long-context" => %{
      breadcrumb_label: "Largest Context Window LLMs",
      category: "Context comparison",
      label: "Compare the largest LLM context windows",
      description:
        "Review active model identities with recorded context limits of 128,000 tokens or more."
    },
    "/models/open-weights" => %{
      breadcrumb_label: "Open-Weight LLM Models",
      category: "Model availability",
      label: "Browse open-weight LLM models",
      description: "Find active text models whose catalog metadata marks open weights as true."
    },
    "/models/video" => %{
      breadcrumb_label: "Video AI Models",
      category: "Media capability",
      label: "Explore video AI models",
      description:
        "Use separate lists for models that accept video and models that generate video."
    }
  }

  @graph %{
    "/llm-models" => [
      "/rankings/ai-models",
      "/rankings/cheapest-llm-api",
      "/rankings/free-llm-api",
      "/models/vision",
      "/models/tool-calling",
      "/models/long-context",
      "/models/open-weights",
      "/models/video"
    ],
    "/rankings/ai-models" => [
      "/llm-models",
      "/rankings/cheapest-llm-api",
      "/rankings/free-llm-api",
      "/models/long-context",
      "/models/tool-calling",
      "/models/vision",
      "/models/open-weights",
      "/models/video"
    ],
    "/rankings/cheapest-llm-api" => [
      "/llm-models",
      "/rankings/ai-models",
      "/rankings/free-llm-api",
      "/models/long-context",
      "/models/tool-calling",
      "/models/open-weights"
    ],
    "/rankings/free-llm-api" => [
      "/llm-models",
      "/rankings/ai-models",
      "/rankings/cheapest-llm-api"
    ],
    "/models/vision" => [
      "/llm-models",
      "/rankings/ai-models",
      "/models/video",
      "/models/tool-calling",
      "/models/open-weights"
    ],
    "/models/tool-calling" => [
      "/llm-models",
      "/rankings/ai-models",
      "/rankings/cheapest-llm-api",
      "/models/vision",
      "/models/long-context",
      "/models/open-weights"
    ],
    "/models/long-context" => [
      "/llm-models",
      "/rankings/ai-models",
      "/rankings/cheapest-llm-api",
      "/models/tool-calling",
      "/models/open-weights"
    ],
    "/models/open-weights" => [
      "/llm-models",
      "/rankings/ai-models",
      "/rankings/cheapest-llm-api",
      "/models/vision",
      "/models/tool-calling",
      "/models/long-context"
    ],
    "/models/video" => [
      "/llm-models",
      "/rankings/ai-models",
      "/models/vision"
    ]
  }

  @spec landing_routes() :: [String.t()]
  def landing_routes, do: @targets |> Map.keys() |> Enum.sort()

  @spec links_for(String.t()) :: [map()]
  def links_for(route) do
    route
    |> PublicRoutes.normalize_path()
    |> then(&Map.get(@graph, &1, []))
    |> Enum.map(fn target_route ->
      @targets
      |> Map.fetch!(target_route)
      |> Map.put(:route, target_route)
    end)
  end

  @spec breadcrumbs_for(String.t()) :: [map()]
  def breadcrumbs_for(route) do
    route = PublicRoutes.normalize_path(route)
    current = Map.fetch!(@targets, route)

    parents =
      cond do
        route == "/llm-models" ->
          []

        route in ["/rankings/ai-models"] ->
          []

        String.starts_with?(route, "/rankings/") ->
          [breadcrumb("/rankings/ai-models")]

        true ->
          [breadcrumb("/llm-models")]
      end

    [%{label: "LLM Catalog", route: "/"}] ++
      parents ++ [%{label: current.breadcrumb_label, route: route}]
  end

  @spec markdown_for(String.t()) :: String.t()
  def markdown_for(route) do
    items =
      route
      |> links_for()
      |> Enum.map_join("\n", fn link ->
        "- [#{link.label}](#{PublicRoutes.absolute(link.route)}) — #{link.description}"
      end)

    """
    ## Related LLM model lists

    #{items}
    """
    |> String.trim()
  end

  attr :current_route, :string, required: true

  def breadcrumbs(assigns) do
    items = breadcrumbs_for(assigns.current_route)

    assigns =
      assigns
      |> assign(:items, items)
      |> assign(:item_count, length(items))

    ~H"""
    <nav aria-label="Breadcrumb" class="mb-5">
      <ol
        class="flex flex-wrap items-center gap-x-2 gap-y-1 text-xs"
        style="color: hsl(var(--muted-foreground));"
      >
        <%= for {item, index} <- Enum.with_index(@items) do %>
          <li class="flex items-center gap-2">
            <span :if={index > 0} aria-hidden="true">/</span>
            <%= if index + 1 == @item_count do %>
              <span aria-current="page">{item.label}</span>
            <% else %>
              <a href={item.route} class="hover:underline hover:opacity-80">{item.label}</a>
            <% end %>
          </li>
        <% end %>
      </ol>
    </nav>
    """
  end

  attr :current_route, :string, required: true

  def link_pack(assigns) do
    assigns = assign(assigns, :links, links_for(assigns.current_route))

    ~H"""
    <section
      id="related-model-lists"
      aria-labelledby="related-model-lists-heading"
      class="mt-12 border-t pt-10"
      style="border-color: hsl(var(--border));"
    >
      <div class="max-w-3xl">
        <p
          class="text-xs uppercase tracking-[0.16em]"
          style="color: hsl(var(--primary));"
        >
          Continue your comparison
        </p>
        <h2
          id="related-model-lists-heading"
          class="mt-2 text-2xl sm:text-3xl font-semibold"
          style="color: hsl(var(--foreground));"
        >
          Related LLM model lists
        </h2>
        <p class="mt-2 text-sm leading-relaxed" style="color: hsl(var(--muted-foreground));">
          Move between the main catalog hubs and the model lists that answer closely related
          questions.
        </p>
      </div>

      <div class="mt-6 grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
        <%= for link <- @links do %>
          <a
            href={link.route}
            class="group rounded-xl border p-5 transition hover:-translate-y-0.5 hover:shadow-md"
            style="border-color: hsl(var(--border)); background-color: hsl(var(--card));"
          >
            <span
              class="text-[11px] uppercase tracking-[0.12em]"
              style="color: hsl(var(--primary));"
            >
              {link.category}
            </span>
            <h3
              class="mt-2 text-base font-semibold group-hover:underline"
              style="color: hsl(var(--foreground));"
            >
              {link.label}
            </h3>
            <p class="mt-2 text-sm leading-relaxed" style="color: hsl(var(--muted-foreground));">
              {link.description}
            </p>
            <span
              class="mt-4 inline-flex items-center gap-1 text-xs font-medium"
              style="color: hsl(var(--primary));"
            >
              Open comparison <.icon name="hero-arrow-right" class="h-3.5 w-3.5" />
            </span>
          </a>
        <% end %>
      </div>
    </section>
    """
  end

  defp breadcrumb(route) do
    target = Map.fetch!(@targets, route)
    %{label: target.breadcrumb_label, route: route}
  end
end

defmodule PetalBoilerplateWeb.LLMModelsLive do
  use PetalBoilerplateWeb, :live_view

  alias PetalBoilerplate.Catalog
  alias PetalBoilerplate.Catalog.LLMModelsList
  alias PetalBoilerplate.SEOContent
  alias PetalBoilerplate.SEOContent.Page
  alias PetalBoilerplateWeb.LandingLinks
  alias PetalBoilerplateWeb.PublicRoutes
  alias PetalBoilerplateWeb.SEO

  @impl true
  def mount(params, _session, socket) do
    {:ok, assign_page(socket, params)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, assign_page(socket, params)}
  end

  @impl true
  def handle_event("filter", %{"search" => search}, socket) do
    {:noreply, push_navigate(socket, to: model_search_path(search))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col" style="background-color: hsl(var(--background));">
      <PetalBoilerplateWeb.ModelComponents.header search_value="" />

      <main class="flex-1 w-full max-w-7xl mx-auto py-6 sm:py-10 px-4 sm:px-6">
        <LandingLinks.breadcrumbs current_route="/llm-models" />

        <section class="max-w-4xl">
          <p class="text-xs uppercase tracking-[0.16em] mb-2" style="color: hsl(var(--primary));">
            Updated {display_date(@snapshot.last_updated)}
          </p>
          <h1
            class="text-3xl sm:text-5xl font-semibold tracking-tight"
            style="color: hsl(var(--foreground));"
          >
            {@page_content.title}
          </h1>
          <p
            class="mt-4 max-w-3xl text-base sm:text-lg leading-relaxed"
            style="color: hsl(var(--muted-foreground));"
          >
            {@page_content.description}
          </p>
        </section>

        <section
          aria-label="List summary"
          class="grid grid-cols-2 lg:grid-cols-4 gap-3 mt-8"
        >
          <.stat_card
            label="Active LLM model IDs"
            value={format_number(@snapshot.model_identity_count)}
          />
          <.stat_card
            label="Executable offers"
            value={format_number(@snapshot.eligible_offer_count)}
          />
          <.stat_card label="API providers" value={format_number(@snapshot.provider_count)} />
          <.stat_card
            label="Catalog records"
            value={format_number(@snapshot.catalog_offer_count)}
          />
        </section>

        <section class="mt-10" aria-labelledby="current-models-heading">
          <div class="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between mb-5">
            <div>
              <h2
                id="current-models-heading"
                class="text-2xl font-semibold"
                style="color: hsl(var(--foreground));"
              >
                Current active LLMs
              </h2>
              <p class="mt-1 text-sm" style="color: hsl(var(--muted-foreground));">
                Page {@snapshot.page} of {@snapshot.total_pages}. Models are ordered by the latest
                recorded metadata update.
              </p>
            </div>
            <a
              href="/?sort=name"
              class="inline-flex items-center gap-2 text-sm font-medium hover:opacity-80"
              style="color: hsl(var(--primary));"
            >
              Search the complete provider catalog <.icon name="hero-arrow-right" class="h-4 w-4" />
            </a>
          </div>

          <div
            class="overflow-x-auto rounded-xl border"
            style="border-color: hsl(var(--border)); background-color: hsl(var(--card));"
          >
            <table class="w-full min-w-[980px] text-left">
              <thead>
                <tr
                  class="border-b text-[11px] uppercase tracking-[0.12em]"
                  style="border-color: hsl(var(--border)); color: hsl(var(--muted-foreground));"
                >
                  <th class="px-4 py-3 font-medium">Model</th>
                  <th class="px-4 py-3 font-medium">Provider offers</th>
                  <th class="px-4 py-3 font-medium">Known capabilities</th>
                  <th class="px-4 py-3 font-medium text-right">Context</th>
                  <th class="px-4 py-3 font-medium text-right">Lowest-input offer</th>
                  <th class="px-4 py-3 font-medium text-right">Updated</th>
                </tr>
              </thead>
              <tbody>
                <%= for entry <- @snapshot.entries do %>
                  <tr
                    class="border-b last:border-b-0 align-top"
                    style="border-color: hsl(var(--border));"
                  >
                    <td class="px-4 py-4">
                      <a
                        href={PublicRoutes.model_path(entry.representative)}
                        class="font-medium hover:underline"
                        style="color: hsl(var(--foreground));"
                      >
                        {entry.name}
                      </a>
                      <div
                        class="mt-1 max-w-[300px] truncate font-mono text-xs"
                        title={entry.model_id}
                        style="color: hsl(var(--muted-foreground));"
                      >
                        {entry.model_id}
                      </div>
                    </td>
                    <td class="px-4 py-4">
                      <div class="text-sm" style="color: hsl(var(--foreground));">
                        {provider_summary(entry.providers)}
                      </div>
                      <div class="mt-1 text-xs" style="color: hsl(var(--muted-foreground));">
                        {entry.provider_count} {offer_label(entry.provider_count)}
                      </div>
                    </td>
                    <td class="px-4 py-4">
                      <div class="flex max-w-[260px] flex-wrap gap-1.5">
                        <%= for capability <- capability_labels(entry.capabilities) do %>
                          <span
                            class="rounded-full px-2 py-1 text-[11px]"
                            style="background-color: hsl(var(--secondary)); color: hsl(var(--secondary-foreground));"
                          >
                            {capability}
                          </span>
                        <% end %>
                      </div>
                    </td>
                    <td
                      class="px-4 py-4 text-right font-mono text-sm"
                      style="color: hsl(var(--foreground));"
                    >
                      {number_or_na(entry.context)}
                    </td>
                    <td class="px-4 py-4 text-right">
                      <div class="font-mono text-sm" style="color: hsl(var(--foreground));">
                        {price_pair(entry.cost_in, entry.cost_out)}
                      </div>
                      <div class="mt-1 text-xs" style="color: hsl(var(--muted-foreground));">
                        per 1M tokens · {humanize_provider(entry.representative.provider)}
                      </div>
                    </td>
                    <td
                      class="px-4 py-4 text-right text-sm whitespace-nowrap"
                      style="color: hsl(var(--muted-foreground));"
                    >
                      {display_date(entry.last_updated)}
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>

          <nav
            aria-label="LLM model list pages"
            class="mt-5 flex items-center justify-between gap-4"
          >
            <%= if @snapshot.page > 1 do %>
              <a
                href={page_path(@snapshot.page - 1)}
                class="inline-flex items-center gap-2 rounded-md border px-3 py-2 text-sm hover:opacity-80"
                style="border-color: hsl(var(--border)); color: hsl(var(--foreground));"
              >
                <.icon name="hero-arrow-left" class="h-4 w-4" /> Previous
              </a>
            <% else %>
              <span />
            <% end %>

            <span class="text-sm" style="color: hsl(var(--muted-foreground));">
              {@snapshot.page} / {@snapshot.total_pages}
            </span>

            <%= if @snapshot.page < @snapshot.total_pages do %>
              <a
                href={page_path(@snapshot.page + 1)}
                class="inline-flex items-center gap-2 rounded-md border px-3 py-2 text-sm hover:opacity-80"
                style="border-color: hsl(var(--border)); color: hsl(var(--foreground));"
              >
                Next <.icon name="hero-arrow-right" class="h-4 w-4" />
              </a>
            <% else %>
              <span />
            <% end %>
          </nav>
        </section>

        <section class="grid items-start gap-5 mt-12 lg:grid-cols-[minmax(0,2fr)_minmax(280px,1fr)]">
          <article
            class="rounded-xl border p-5 sm:p-6"
            style="border-color: hsl(var(--border)); background-color: hsl(var(--card));"
          >
            <div class="prose prose-sm max-w-none dark:prose-invert">
              <h2>{@page_content.methodology.name}</h2>
              <p>{@page_content.methodology.summary}</p>

              <h3>Inclusion criteria</h3>
              <ul>
                <%= for criterion <- @page_content.methodology.inclusion_criteria do %>
                  <li>{criterion}</li>
                <% end %>
              </ul>

              <%= if @page_content.methodology.exclusion_criteria != [] do %>
                <h3>Exclusions</h3>
                <ul>
                  <%= for criterion <- @page_content.methodology.exclusion_criteria do %>
                    <li>{criterion}</li>
                  <% end %>
                </ul>
              <% end %>

              <h3>Data rules</h3>
              <ul>
                <%= for rule <- @page_content.methodology.rules do %>
                  <li><strong>{rule.label}:</strong> {rule.description}</li>
                <% end %>
              </ul>

              <%= if @page_content.methodology.caveats != [] do %>
                <h3>Limits of the data</h3>
                <ul>
                  <%= for caveat <- @page_content.methodology.caveats do %>
                    <li>{caveat}</li>
                  <% end %>
                </ul>
              <% end %>

              {Phoenix.HTML.raw(@page_content.body)}

              <h2>Sources</h2>
              <ul>
                <%= for source <- @page_content.sources do %>
                  <li>
                    <a href={source.url} rel="noreferrer">{source.name}</a>
                    <%= if source.note do %>
                      — {source.note}
                    <% end %>
                    <small>Checked {Date.to_iso8601(source.retrieved_at)}.</small>
                  </li>
                <% end %>
              </ul>
              <p>
                See <a href="/about">About llmdb.xyz</a> for more information about the data.
              </p>
            </div>
          </article>

          <article
            class="rounded-xl border p-5 sm:p-6 lg:sticky lg:top-6"
            style="border-color: hsl(var(--border)); background-color: hsl(var(--card));"
          >
            <h2 class="text-xl font-semibold" style="color: hsl(var(--foreground));">
              Use the data
            </h2>
            <p class="mt-3 text-sm leading-relaxed" style="color: hsl(var(--muted-foreground));">
              People can browse the table. Agents can request the Markdown version or query the
              catalog through MCP.
            </p>
            <div class="mt-5 flex flex-wrap gap-3">
              <a
                href="/llm-models.md"
                class="inline-flex items-center gap-2 rounded-md border px-3 py-2 text-sm hover:opacity-80"
                style="border-color: hsl(var(--border)); color: hsl(var(--foreground));"
              >
                <.icon name="hero-document-text" class="h-4 w-4" /> Markdown
              </a>
              <a
                href="/llms.txt"
                class="inline-flex items-center gap-2 rounded-md border px-3 py-2 text-sm hover:opacity-80"
                style="border-color: hsl(var(--border)); color: hsl(var(--foreground));"
              >
                <.icon name="hero-command-line" class="h-4 w-4" /> Agent guide
              </a>
              <a
                href="/about"
                class="inline-flex items-center gap-2 rounded-md border px-3 py-2 text-sm hover:opacity-80"
                style="border-color: hsl(var(--border)); color: hsl(var(--foreground));"
              >
                <.icon name="hero-information-circle" class="h-4 w-4" /> Data sources
              </a>
            </div>
          </article>
        </section>

        <LandingLinks.link_pack current_route="/llm-models" />
      </main>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :value, :string, required: true

  defp stat_card(assigns) do
    ~H"""
    <div
      class="rounded-xl border p-4 sm:p-5"
      style="border-color: hsl(var(--border)); background-color: hsl(var(--card));"
    >
      <div class="text-2xl sm:text-3xl font-semibold" style="color: hsl(var(--foreground));">
        {@value}
      </div>
      <div class="mt-1 text-xs sm:text-sm" style="color: hsl(var(--muted-foreground));">
        {@label}
      </div>
    </div>
    """
  end

  defp assign_page(socket, params) do
    snapshot = params |> Map.get("page") |> parse_page() |> LLMModelsList.snapshot()
    page_content = SEOContent.get_page!("/llm-models")
    description = Page.seo_description(page_content)
    title = Page.seo_title(page_content)

    assign(socket,
      snapshot: snapshot,
      page_content: page_content,
      page_title: title,
      page_description: description,
      canonical_url: PublicRoutes.absolute("/llm-models"),
      og_image: PublicRoutes.absolute("/og/home.png"),
      robots: if(map_size(params) > 0, do: ["noindex", "follow"]),
      structured_data: SEO.llm_models_list_structured_data(snapshot, page_content)
    )
  end

  defp parse_page(page) when is_integer(page) and page > 0, do: page

  defp parse_page(page) when is_binary(page) do
    case Integer.parse(page) do
      {parsed, ""} when parsed > 0 -> parsed
      _ -> 1
    end
  end

  defp parse_page(_page), do: 1

  defp page_path(1), do: "/llm-models"
  defp page_path(page), do: "/llm-models?page=#{page}"

  defp model_search_path(search) do
    query = String.trim(search)
    if query == "", do: "/", else: "/?q=#{URI.encode_www_form(query)}"
  end

  defp provider_summary(providers) do
    visible = providers |> Enum.take(3) |> Enum.map(&humanize_provider/1)
    hidden_count = max(length(providers) - length(visible), 0)

    if hidden_count > 0 do
      Enum.join(visible, ", ") <> " +#{hidden_count}"
    else
      Enum.join(visible, ", ")
    end
  end

  defp offer_label(1), do: "offer"
  defp offer_label(_count), do: "offers"

  defp capability_labels(capabilities) do
    [
      {:reasoning, "Reasoning"},
      {:tools, "Tools"},
      {:chat, "Chat"},
      {:json_schema, "JSON schema"},
      {:streaming_text, "Streaming"}
    ]
    |> Enum.filter(fn {key, _label} -> MapSet.member?(capabilities, key) end)
    |> Enum.map(fn {_key, label} -> label end)
    |> Enum.take(4)
    |> case do
      [] -> ["Text generation"]
      labels -> labels
    end
  end

  defp price_pair(input_cost, output_cost) do
    "#{cost_or_na(input_cost)} / #{cost_or_na(output_cost)}"
  end

  defp cost_or_na(cost) when is_number(cost) and cost >= 0, do: Catalog.format_cost(cost)
  defp cost_or_na(_cost), do: "N/A"

  defp number_or_na(number) when is_number(number) and number > 0,
    do: Catalog.format_number(number)

  defp number_or_na(_number), do: "N/A"

  defp display_date(nil), do: "unknown"

  defp display_date(date) do
    case Date.from_iso8601(date) do
      {:ok, parsed} -> Calendar.strftime(parsed, "%B %-d, %Y")
      _ -> date
    end
  end

  defp humanize_provider(provider) do
    provider
    |> to_string()
    |> Phoenix.Naming.humanize()
  end

  defp format_number(number), do: Catalog.format_number(number)
end

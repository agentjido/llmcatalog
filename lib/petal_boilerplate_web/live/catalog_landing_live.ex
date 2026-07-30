defmodule PetalBoilerplateWeb.CatalogLandingLive do
  use PetalBoilerplateWeb, :live_view

  alias PetalBoilerplate.Catalog
  alias PetalBoilerplate.Catalog.LandingPages
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
    query = String.trim(search)
    path = if query == "", do: "/", else: "/?q=#{URI.encode_www_form(query)}"
    {:noreply, push_navigate(socket, to: path)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex flex-col" style="background-color: hsl(var(--background));">
      <PetalBoilerplateWeb.ModelComponents.header search_value="" />

      <main class="flex-1 w-full max-w-7xl mx-auto py-6 sm:py-10 px-4 sm:px-6">
        <LandingLinks.breadcrumbs current_route={@route} />

        <section class="max-w-4xl">
          <p class="text-xs uppercase tracking-[0.16em] mb-2" style="color: hsl(var(--primary));">
            Catalog data · Updated {display_date(@snapshot.last_updated)}
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
          <div class="mt-5 flex flex-wrap gap-2 text-xs">
            <span
              class="rounded-full border px-3 py-1.5"
              style="border-color: hsl(var(--border)); color: hsl(var(--muted-foreground));"
            >
              Objective catalog fields
            </span>
            <span
              class="rounded-full border px-3 py-1.5"
              style="border-color: hsl(var(--border)); color: hsl(var(--muted-foreground));"
            >
              No overall quality score
            </span>
          </div>
        </section>

        <section aria-label="Page summary" class="grid grid-cols-2 lg:grid-cols-4 gap-3 mt-8">
          <.stat_card
            label={@snapshot.count_label}
            value={format_number(@snapshot.total_count)}
          />
          <.stat_card label="Providers shown" value={format_number(@snapshot.provider_count)} />
          <.stat_card label="Data sections" value={format_number(length(@snapshot.sections))} />
          <.stat_card
            label="Catalog records"
            value={format_number(Catalog.total_model_count())}
          />
        </section>

        <%= for section <- @snapshot.sections do %>
          <section class="mt-10" aria-label={section.title}>
            <div class="mb-5 flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between">
              <div>
                <h2 class="text-2xl font-semibold" style="color: hsl(var(--foreground));">
                  {section.title}
                </h2>
                <p class="mt-1 max-w-3xl text-sm" style="color: hsl(var(--muted-foreground));">
                  {section.description}
                </p>
              </div>
              <p class="text-sm whitespace-nowrap" style="color: hsl(var(--muted-foreground));">
                Showing {length(section.entries)} of {format_number(section.total_count)}
              </p>
            </div>

            <div
              class="overflow-x-auto rounded-xl border"
              style="border-color: hsl(var(--border)); background-color: hsl(var(--card));"
            >
              <table class="w-full min-w-[960px] text-left">
                <thead>
                  <tr
                    class="border-b text-[11px] uppercase tracking-[0.12em]"
                    style="border-color: hsl(var(--border)); color: hsl(var(--muted-foreground));"
                  >
                    <th class="px-4 py-3 font-medium">Model</th>
                    <th class="px-4 py-3 font-medium">Provider offers</th>
                    <th class="px-4 py-3 font-medium">Why listed</th>
                    <th class="px-4 py-3 font-medium text-right">Context</th>
                    <th class="px-4 py-3 font-medium text-right">Input / output price</th>
                    <th class="px-4 py-3 font-medium text-right">Updated</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for entry <- section.entries do %>
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
                        <span
                          class="inline-flex rounded-full px-2.5 py-1 text-xs"
                          style="background-color: hsl(var(--secondary)); color: hsl(var(--secondary-foreground));"
                        >
                          {entry.reason}
                        </span>
                      </td>
                      <td
                        class="px-4 py-4 text-right font-mono text-sm"
                        style="color: hsl(var(--foreground));"
                      >
                        {number_or_na(entry.context)}
                      </td>
                      <td class="px-4 py-4 text-right">
                        <div class="font-mono text-sm" style="color: hsl(var(--foreground));">
                          {price_pair(entry, @action)}
                        </div>
                        <div class="mt-1 text-xs" style="color: hsl(var(--muted-foreground));">
                          {price_note(@action, section.title)}
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
          </section>
        <% end %>

        <nav
          :if={@snapshot.total_pages > 1}
          aria-label="Landing page results"
          class="mt-5 flex items-center justify-between gap-4"
        >
          <%= if @snapshot.page > 1 do %>
            <a
              href={page_path(@route, @snapshot.page - 1)}
              class="rounded-md border px-3 py-2 text-sm hover:opacity-80"
              style="border-color: hsl(var(--border)); color: hsl(var(--foreground));"
            >
              Previous
            </a>
          <% else %>
            <span />
          <% end %>
          <span class="text-sm" style="color: hsl(var(--muted-foreground));">
            {@snapshot.page} / {@snapshot.total_pages}
          </span>
          <%= if @snapshot.page < @snapshot.total_pages do %>
            <a
              href={page_path(@route, @snapshot.page + 1)}
              class="rounded-md border px-3 py-2 text-sm hover:opacity-80"
              style="border-color: hsl(var(--border)); color: hsl(var(--foreground));"
            >
              Next
            </a>
          <% else %>
            <span />
          <% end %>
        </nav>

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
              <h3>Exclusions</h3>
              <ul>
                <%= for criterion <- @page_content.methodology.exclusion_criteria do %>
                  <li>{criterion}</li>
                <% end %>
              </ul>
              <h3>Data rules</h3>
              <ul>
                <%= for rule <- @page_content.methodology.rules do %>
                  <li><strong>{rule.label}:</strong> {rule.description}</li>
                <% end %>
              </ul>
              <h3>Limits of the data</h3>
              <ul>
                <%= for caveat <- @page_content.methodology.caveats do %>
                  <li>{caveat}</li>
                <% end %>
              </ul>
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
            </div>
          </article>

          <aside class="space-y-5 lg:sticky lg:top-6">
            <article
              class="rounded-xl border p-5 sm:p-6"
              style="border-color: hsl(var(--border)); background-color: hsl(var(--card));"
            >
              <h2 class="text-xl font-semibold" style="color: hsl(var(--foreground));">
                Use the data
              </h2>
              <div class="mt-4 flex flex-wrap gap-3">
                <a
                  href={PublicRoutes.markdown_path(@route)}
                  class="rounded-md border px-3 py-2 text-sm hover:opacity-80"
                  style="border-color: hsl(var(--border)); color: hsl(var(--foreground));"
                >
                  Markdown
                </a>
                <a
                  href="/llms.txt"
                  class="rounded-md border px-3 py-2 text-sm hover:opacity-80"
                  style="border-color: hsl(var(--border)); color: hsl(var(--foreground));"
                >
                  Agent guide
                </a>
              </div>
            </article>
          </aside>
        </section>

        <LandingLinks.link_pack current_route={@route} />
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
    action = socket.assigns.live_action
    route = LandingPages.route_for(action)
    page_content = SEOContent.get_page!(route)
    snapshot = LandingPages.snapshot(action, parse_page(params["page"]))

    assign(socket,
      action: action,
      route: route,
      page_content: page_content,
      snapshot: snapshot,
      page_title: Page.seo_title(page_content),
      page_description: Page.seo_description(page_content),
      canonical_url: PublicRoutes.absolute(route),
      og_image: PublicRoutes.absolute("/og/home.png"),
      robots: if(map_size(params) > 0, do: ["noindex", "follow"]),
      structured_data: SEO.catalog_landing_structured_data(snapshot, page_content)
    )
  end

  defp parse_page(value) when is_binary(value) do
    case Integer.parse(value) do
      {page, ""} when page > 0 -> page
      _other -> 1
    end
  end

  defp parse_page(_value), do: 1

  defp page_path(route, 1), do: route
  defp page_path(route, page), do: "#{route}?page=#{page}"

  defp provider_summary(providers) do
    visible = providers |> Enum.take(3) |> Enum.map(&humanize_provider/1)
    hidden_count = max(length(providers) - length(visible), 0)

    if hidden_count > 0,
      do: Enum.join(visible, ", ") <> " +#{hidden_count}",
      else: Enum.join(visible, ", ")
  end

  defp price_pair(_entry, :video), do: "See model"

  defp price_pair(entry, _action) do
    "#{cost_or_na(entry.cost_in)} / #{cost_or_na(entry.cost_out)}"
  end

  defp price_note(:cheapest, _section), do: "per 1M tokens"
  defp price_note(:video, _section), do: "media units vary"
  defp price_note(:ai_models, "Lowest paid input-token prices"), do: "per 1M tokens"
  defp price_note(_action, _section), do: "per 1M tokens, when known"

  defp cost_or_na(cost) when is_number(cost) and cost >= 0, do: Catalog.format_cost(cost)
  defp cost_or_na(_cost), do: "N/A"

  defp number_or_na(number) when is_number(number) and number > 0,
    do: Catalog.format_number(number)

  defp number_or_na(_number), do: "N/A"

  defp display_date(nil), do: "unknown"

  defp display_date(date) do
    case Date.from_iso8601(date) do
      {:ok, parsed} -> Calendar.strftime(parsed, "%B %-d, %Y")
      _other -> date
    end
  end

  defp humanize_provider(provider), do: provider |> to_string() |> Phoenix.Naming.humanize()
  defp offer_label(1), do: "offer"
  defp offer_label(_count), do: "offers"
  defp format_number(number), do: Catalog.format_number(number)
end

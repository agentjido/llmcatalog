defmodule PetalBoilerplateWeb.ProvidersLive do
  use PetalBoilerplateWeb, :live_view

  alias PetalBoilerplate.Catalog.ProviderDirectory
  alias PetalBoilerplateWeb.PublicRoutes
  alias PetalBoilerplateWeb.SEO

  @route "/providers"
  @title "Model Provider Directory"
  @description "Browse every catalog provider. See its model records and models with an explicit Evaluate capability."

  @impl true
  def mount(_params, _session, socket) do
    entries = ProviderDirectory.entries()

    {:ok,
     assign(socket,
       entries: entries,
       page_title: @title,
       page_description: @description,
       canonical_url: PublicRoutes.absolute(@route),
       og_image: PublicRoutes.absolute("/og/home.png"),
       structured_data: SEO.provider_directory_structured_data(entries)
     )}
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
        <nav aria-label="Breadcrumb" class="mb-5 text-xs" style="color: hsl(var(--muted-foreground));">
          <a href="/" class="hover:underline">LLM Catalog</a>
          <span aria-hidden="true"> / </span>
          <span aria-current="page">Providers</span>
        </nav>

        <header class="max-w-3xl">
          <h1
            class="text-3xl sm:text-5xl font-semibold tracking-tight"
            style="color: hsl(var(--foreground));"
          >
            Model Provider Directory
          </h1>
          <p
            class="mt-4 text-base sm:text-lg leading-relaxed"
            style="color: hsl(var(--muted-foreground));"
          >
            Browse every provider in the catalog. Counts include all catalog model records,
            including records that are deprecated, retired, or catalog only. Evaluation counts
            include active records with an explicit Evaluate capability.
          </p>
          <p class="mt-3 text-sm" style="color: hsl(var(--muted-foreground));">
            A catalog capability does not confirm that ReqLLM can call the model.
          </p>
          <a
            href="/models/evaluation"
            class="mt-4 inline-block text-sm font-medium hover:underline"
            style="color: hsl(var(--primary));"
          >
            Browse evaluation models
          </a>
        </header>

        <section aria-labelledby="providers-heading" class="mt-10">
          <div class="flex flex-wrap items-end justify-between gap-2">
            <h2
              id="providers-heading"
              class="text-2xl font-semibold"
              style="color: hsl(var(--foreground));"
            >
              All providers
            </h2>
            <p class="text-sm" style="color: hsl(var(--muted-foreground));">
              {length(@entries)} providers
            </p>
          </div>

          <ul class="mt-5 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            <%= for entry <- @entries do %>
              <li
                class="rounded-xl border p-5"
                style="border-color: hsl(var(--border)); background-color: hsl(var(--card));"
              >
                <h3 class="text-lg font-semibold" style="color: hsl(var(--foreground));">
                  {entry.name}
                </h3>
                <p
                  class="mt-1 font-mono text-xs break-all"
                  style="color: hsl(var(--muted-foreground));"
                >
                  {entry.id}
                </p>
                <p class="mt-4 text-sm" style="color: hsl(var(--foreground));">
                  {entry.model_count} model records
                  <span :if={entry.evaluation_count > 0}>
                    · {entry.evaluation_count} evaluation models
                  </span>
                </p>
                <div class="mt-4 flex flex-wrap gap-4 text-sm">
                  <a
                    href={ProviderDirectory.catalog_path(entry.id)}
                    class="font-medium hover:underline"
                    style="color: hsl(var(--primary));"
                  >
                    Browse {entry.name} models
                  </a>
                  <a
                    :if={entry.evaluation_count > 0}
                    href="/models/evaluation"
                    class="font-medium hover:underline"
                    style="color: hsl(var(--primary));"
                  >
                    Evaluation models
                  </a>
                </div>
              </li>
            <% end %>
          </ul>
        </section>
      </main>
    </div>
    """
  end
end

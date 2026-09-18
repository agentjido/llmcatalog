defmodule PetalBoilerplateWeb.EvaluationLive do
  use PetalBoilerplateWeb, :live_view

  alias PetalBoilerplate.Catalog
  alias PetalBoilerplate.Catalog.LandingPages
  alias PetalBoilerplateWeb.PublicRoutes
  alias PetalBoilerplateWeb.SEO

  @route "/models/evaluation"
  @title "Evaluation Models"
  @description "Find active catalog models that return typed decisions for evaluation questions. See each exact provider model spec, recorded context, and known prices."

  @impl true
  def mount(_params, _session, socket) do
    snapshot = LandingPages.evaluation_snapshot(Catalog.list_all_models())

    {:ok,
     assign(socket,
       snapshot: snapshot,
       page_title: @title,
       page_description: @description,
       canonical_url: PublicRoutes.absolute(@route),
       og_image: PublicRoutes.absolute("/og/home.png"),
       structured_data: SEO.evaluation_structured_data(snapshot)
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
          <span aria-current="page">Evaluation Models</span>
        </nav>

        <header class="max-w-3xl">
          <p class="text-xs uppercase tracking-[0.16em] mb-2" style="color: hsl(var(--primary));">
            Explicit catalog capability
          </p>
          <h1
            class="text-3xl sm:text-5xl font-semibold tracking-tight"
            style="color: hsl(var(--foreground));"
          >
            Evaluation Models
          </h1>
          <p
            class="mt-4 text-base sm:text-lg leading-relaxed"
            style="color: hsl(var(--muted-foreground));"
          >
            These models return typed decisions for evaluation questions, such as choices,
            scores, and boolean answers. Each listed record has an explicit Evaluate capability
            in the catalog.
          </p>
          <p class="mt-3 text-sm" style="color: hsl(var(--muted-foreground));">
            A catalog capability does not confirm that ReqLLM can call the model. Check the
            provider adapter before you use a model spec in an application.
          </p>
          <div class="mt-4 flex flex-wrap gap-5 text-sm">
            <a
              href="/?caps=evaluate"
              class="font-medium hover:underline"
              style="color: hsl(var(--primary));"
            >
              Filter the model catalog
            </a>
            <a
              href="/providers"
              class="font-medium hover:underline"
              style="color: hsl(var(--primary));"
            >
              Browse all providers
            </a>
          </div>
        </header>

        <section aria-label="Page summary" class="mt-8 grid grid-cols-2 gap-3 sm:max-w-xl">
          <div
            class="rounded-xl border p-4"
            style="border-color: hsl(var(--border)); background-color: hsl(var(--card));"
          >
            <p class="text-2xl font-semibold" style="color: hsl(var(--foreground));">
              {@snapshot.total_count}
            </p>
            <p class="text-sm" style="color: hsl(var(--muted-foreground));">Model specs</p>
          </div>
          <div
            class="rounded-xl border p-4"
            style="border-color: hsl(var(--border)); background-color: hsl(var(--card));"
          >
            <p class="text-2xl font-semibold" style="color: hsl(var(--foreground));">
              {@snapshot.provider_count}
            </p>
            <p class="text-sm" style="color: hsl(var(--muted-foreground));">Providers</p>
          </div>
        </section>

        <%= for section <- @snapshot.sections do %>
          <section class="mt-10" aria-label={section.title}>
            <h2 class="text-2xl font-semibold" style="color: hsl(var(--foreground));">
              {section.title}
            </h2>
            <p class="mt-1 text-sm" style="color: hsl(var(--muted-foreground));">
              {section.total_count} model specs
            </p>
            <ul class="mt-5 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
              <%= for entry <- section.entries do %>
                <li
                  class="rounded-xl border p-5"
                  style="border-color: hsl(var(--border)); background-color: hsl(var(--card));"
                >
                  <h3 class="text-lg font-semibold" style="color: hsl(var(--foreground));">
                    <a href={PublicRoutes.model_path(entry.representative)} class="hover:underline">
                      {entry.name}
                    </a>
                  </h3>
                  <p
                    class="mt-2 font-mono text-xs break-all"
                    style="color: hsl(var(--muted-foreground));"
                  >
                    {model_spec(entry)}
                  </p>
                  <p
                    :if={entry.representative.catalog_only == true}
                    class="mt-3 rounded-md px-2 py-1 text-xs"
                    style="background-color: hsl(var(--secondary)); color: hsl(var(--secondary-foreground));"
                  >
                    Catalog only. ReqLLM call support is not confirmed.
                  </p>
                  <dl class="mt-4 grid grid-cols-2 gap-3 text-sm">
                    <div>
                      <dt style="color: hsl(var(--muted-foreground));">Context</dt>
                      <dd class="font-medium" style="color: hsl(var(--foreground));">
                        {number_or_na(entry.context)}
                      </dd>
                    </div>
                    <div>
                      <dt style="color: hsl(var(--muted-foreground));">Input / output price</dt>
                      <dd class="font-medium" style="color: hsl(var(--foreground));">
                        {price_pair(entry)}
                      </dd>
                    </div>
                  </dl>
                  <p class="mt-3 text-xs" style="color: hsl(var(--muted-foreground));">
                    Updated {entry.last_updated || "unknown"}
                  </p>
                </li>
              <% end %>
            </ul>
          </section>
        <% end %>

        <section class="mt-12 max-w-3xl border-t pt-8" style="border-color: hsl(var(--border));">
          <h2 class="text-xl font-semibold" style="color: hsl(var(--foreground));">
            How this list works
          </h2>
          <p class="mt-3 text-sm leading-relaxed" style="color: hsl(var(--muted-foreground));">
            This list includes active records only when capabilities.evaluate is true.
            It uses the exact provider model ID and does not infer Evaluate from a model name,
            JSON output, or structured output. Known prices are catalog input and output rates
            per one million tokens. Evaluation billing can use other units. Confirm price and
            context with the provider before use.
          </p>
          <a
            href="/models/evaluation.md"
            class="mt-4 inline-block text-sm font-medium hover:underline"
            style="color: hsl(var(--primary));"
          >
            Read this list as Markdown
          </a>
        </section>
      </main>
    </div>
    """
  end

  defp model_spec(entry), do: "#{entry.representative.provider}:#{entry.model_id}"

  defp number_or_na(value) when is_number(value) and value > 0,
    do: Catalog.format_number(value)

  defp number_or_na(_value), do: "N/A"

  defp price_pair(entry), do: "#{price(entry.cost_in)} / #{price(entry.cost_out)}"

  defp price(value) when is_number(value),
    do: "$#{:erlang.float_to_binary(value * 1.0, decimals: 3)}"

  defp price(_value), do: "N/A"
end

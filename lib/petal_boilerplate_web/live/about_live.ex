defmodule PetalBoilerplateWeb.AboutLive do
  use PetalBoilerplateWeb, :live_view

  alias PetalBoilerplate.Catalog
  alias PetalBoilerplateWeb.ModelMetadataFeedback
  alias PetalBoilerplateWeb.PublicRoutes
  alias PetalBoilerplateWeb.SEO

  @impl true
  def mount(_params, _session, socket) do
    model_count = Catalog.total_model_count()
    provider_count = length(Catalog.list_providers())

    description =
      "Learn about LLM Catalog, a database of #{model_count} LLM models across #{provider_count} providers. Powered by the open-source llmdb project."

    {:ok,
     assign(socket,
       model_count: model_count,
       provider_count: provider_count,
       page_title: "About",
       page_description: description,
       canonical_url: PublicRoutes.absolute("/about"),
       og_image: PublicRoutes.absolute("/og/about.png"),
       structured_data: SEO.about_structured_data(description)
     )}
  end

  @impl true
  def handle_event("filter", %{"search" => search}, socket) do
    {:noreply, push_navigate(socket, to: model_search_path(search))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex min-h-screen flex-col" style="background-color: hsl(var(--background));">
      <PetalBoilerplateWeb.ModelComponents.header search_value="" />

      <main class="mx-auto w-full max-w-3xl flex-1 px-4 py-10 sm:px-6 sm:py-14">
        <header class="border-b pb-9" style="border-color: hsl(var(--border));">
          <h1
            class="text-3xl font-semibold tracking-tight sm:text-4xl"
            style="color: hsl(var(--foreground));"
          >
            About LLM Catalog
          </h1>
          <p
            class="mt-4 max-w-2xl text-lg leading-8"
            style="color: hsl(var(--muted-foreground));"
          >
            LLM Catalog by
            <a
              href="https://jidokahq.com/"
              target="_blank"
              rel="noopener noreferrer"
              class="font-medium hover:underline focus-visible:outline-2 focus-visible:outline-offset-2"
              style="color: hsl(var(--foreground)); text-underline-offset: 3px;"
            >Jidoka Labs</a>
            is a public database of {Catalog.format_number(@model_count)} models across {@provider_count} providers. It helps people compare model availability,
            capabilities, context limits, modalities, and published prices.
          </p>
          <p class="mt-4 max-w-2xl leading-7" style="color: hsl(var(--muted-foreground));">
            Catalog data comes from <a
              href="https://github.com/agentjido/llmdb"
              target="_blank"
              rel="noopener noreferrer"
              class="font-medium hover:underline focus-visible:outline-2 focus-visible:outline-offset-2"
              style="color: hsl(var(--foreground)); text-underline-offset: 3px;"
            >llmdb</a>, an open-source model database that also supplies metadata to <a
              href="https://hex.pm/packages/req_llm"
              target="_blank"
              rel="noopener noreferrer"
              class="font-medium hover:underline focus-visible:outline-2 focus-visible:outline-offset-2"
              style="color: hsl(var(--foreground)); text-underline-offset: 3px;"
            >req_llm</a>.
          </p>
        </header>

        <section class="border-b py-9" style="border-color: hsl(var(--border));">
          <h2 class="text-xl font-semibold" style="color: hsl(var(--foreground));">
            What you can compare
          </h2>
          <ul
            class="mt-5 grid gap-x-8 gap-y-3 sm:grid-cols-2"
            style="color: hsl(var(--muted-foreground));"
          >
            <li>Provider availability and model aliases</li>
            <li>Capabilities and input or output modalities</li>
            <li>Context windows and output limits</li>
            <li>Input and output prices when published</li>
            <li>Architecture and model-size metadata when available</li>
            <li>Lifecycle state and recent metadata changes</li>
          </ul>
        </section>

        <section class="border-b py-9" style="border-color: hsl(var(--border));">
          <h2 class="text-xl font-semibold" style="color: hsl(var(--foreground));">
            How the data is built
          </h2>
          <p class="mt-4 leading-7" style="color: hsl(var(--muted-foreground));">
            llmdb collects, normalizes, validates, and merges model records from public catalogs and provider APIs.
            Curated TOML corrections take priority when an upstream record needs more detail or a correction.
          </p>

          <ul class="mt-6 divide-y border-y" style="border-color: hsl(var(--border));">
            <li class="py-3 sm:flex sm:gap-5">
              <a
                href="https://models.dev"
                target="_blank"
                rel="noopener noreferrer"
                class="block shrink-0 font-medium hover:underline focus-visible:outline-2 focus-visible:outline-offset-2 sm:w-36"
                style="color: hsl(var(--foreground)); text-underline-offset: 3px;"
              >
                models.dev
              </a>
              <span class="mt-1 block text-sm sm:mt-0" style="color: hsl(var(--muted-foreground));">
                Community model catalog with pricing, limits, and capabilities
              </span>
            </li>
            <li class="py-3 sm:flex sm:gap-5">
              <a
                href="https://platform.openai.com/docs/api-reference/models"
                target="_blank"
                rel="noopener noreferrer"
                class="block shrink-0 font-medium hover:underline focus-visible:outline-2 focus-visible:outline-offset-2 sm:w-36"
                style="color: hsl(var(--foreground)); text-underline-offset: 3px;"
              >
                OpenAI
              </a>
              <span class="mt-1 block text-sm sm:mt-0" style="color: hsl(var(--muted-foreground));">
                Official Models API
              </span>
            </li>
            <li class="py-3 sm:flex sm:gap-5">
              <a
                href="https://docs.anthropic.com/en/api/models"
                target="_blank"
                rel="noopener noreferrer"
                class="block shrink-0 font-medium hover:underline focus-visible:outline-2 focus-visible:outline-offset-2 sm:w-36"
                style="color: hsl(var(--foreground)); text-underline-offset: 3px;"
              >
                Anthropic
              </a>
              <span class="mt-1 block text-sm sm:mt-0" style="color: hsl(var(--muted-foreground));">
                Official Models API
              </span>
            </li>
            <li class="py-3 sm:flex sm:gap-5">
              <a
                href="https://ai.google.dev/gemini-api/docs/models"
                target="_blank"
                rel="noopener noreferrer"
                class="block shrink-0 font-medium hover:underline focus-visible:outline-2 focus-visible:outline-offset-2 sm:w-36"
                style="color: hsl(var(--foreground)); text-underline-offset: 3px;"
              >
                Google
              </a>
              <span class="mt-1 block text-sm sm:mt-0" style="color: hsl(var(--muted-foreground));">
                Official Gemini model documentation
              </span>
            </li>
            <li class="py-3 sm:flex sm:gap-5">
              <a
                href="https://docs.x.ai/api"
                target="_blank"
                rel="noopener noreferrer"
                class="block shrink-0 font-medium hover:underline focus-visible:outline-2 focus-visible:outline-offset-2 sm:w-36"
                style="color: hsl(var(--foreground)); text-underline-offset: 3px;"
              >
                xAI
              </a>
              <span class="mt-1 block text-sm sm:mt-0" style="color: hsl(var(--muted-foreground));">
                Official API documentation
              </span>
            </li>
            <li class="py-3 sm:flex sm:gap-5">
              <a
                href="https://openrouter.ai"
                target="_blank"
                rel="noopener noreferrer"
                class="block shrink-0 font-medium hover:underline focus-visible:outline-2 focus-visible:outline-offset-2 sm:w-36"
                style="color: hsl(var(--foreground)); text-underline-offset: 3px;"
              >
                OpenRouter
              </a>
              <span class="mt-1 block text-sm sm:mt-0" style="color: hsl(var(--muted-foreground));">
                Aggregated catalog across many providers
              </span>
            </li>
          </ul>

          <p class="mt-5 text-sm leading-6" style="color: hsl(var(--muted-foreground));">
            Special thanks to models.dev. Its open, community-maintained dataset is a foundational source for this catalog.
          </p>
        </section>

        <section class="border-b py-9" style="border-color: hsl(var(--border));">
          <h2 class="text-xl font-semibold" style="color: hsl(var(--foreground));">
            Open source
          </h2>
          <p class="mt-4 leading-7" style="color: hsl(var(--muted-foreground));">
            LLM Catalog and llmdb are open-source projects. Review the source, inspect the package,
            or submit a correction when model data is incomplete.
          </p>
          <div class="mt-5 flex flex-wrap gap-2">
            <a
              href="https://github.com/agentjido/llmdb"
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex h-9 items-center rounded-md border px-3 text-sm font-medium hover:bg-[hsl(var(--muted))] focus-visible:outline-2 focus-visible:outline-offset-2"
              style="border-color: hsl(var(--border)); color: hsl(var(--foreground));"
            >
              llmdb on GitHub
            </a>
            <a
              href="https://hex.pm/packages/llm_db"
              target="_blank"
              rel="noopener noreferrer"
              class="inline-flex h-9 items-center rounded-md border px-3 text-sm font-medium hover:bg-[hsl(var(--muted))] focus-visible:outline-2 focus-visible:outline-offset-2"
              style="border-color: hsl(var(--border)); color: hsl(var(--foreground));"
            >
              llmdb on Hex
            </a>
          </div>
        </section>

        <section class="pt-9">
          <h2 class="text-xl font-semibold" style="color: hsl(var(--foreground));">
            Project and community
          </h2>
          <p class="mt-4 leading-7" style="color: hsl(var(--muted-foreground));">
            Built by
            <a
              href="https://mike-hostetler.com"
              target="_blank"
              rel="noopener noreferrer"
              class="font-medium hover:underline focus-visible:outline-2 focus-visible:outline-offset-2"
              style="color: hsl(var(--foreground)); text-underline-offset: 3px;"
            >Mike Hostetler</a>
            at <a
              href="https://jidokahq.com/"
              target="_blank"
              rel="noopener noreferrer"
              class="font-medium hover:underline focus-visible:outline-2 focus-visible:outline-offset-2"
              style="color: hsl(var(--foreground)); text-underline-offset: 3px;"
            >Jidoka Labs</a>. Corrections, site feedback, and contributions are welcome.
          </p>
          <nav aria-label="Project links" class="mt-5 flex flex-wrap gap-x-6 gap-y-3 text-sm">
            <a
              href={ModelMetadataFeedback.issue_url()}
              target="_blank"
              rel="noopener noreferrer"
              class="font-medium hover:underline focus-visible:outline-2 focus-visible:outline-offset-2"
              style="color: hsl(var(--foreground)); text-underline-offset: 3px;"
            >Report model data</a>
            <a
              href="https://github.com/agentjido/llmcatalog/issues"
              target="_blank"
              rel="noopener noreferrer"
              class="font-medium hover:underline focus-visible:outline-2 focus-visible:outline-offset-2"
              style="color: hsl(var(--foreground)); text-underline-offset: 3px;"
            >Report a site issue</a>
            <a
              href="https://jido.run/discord"
              target="_blank"
              rel="noopener noreferrer"
              class="font-medium hover:underline focus-visible:outline-2 focus-visible:outline-offset-2"
              style="color: hsl(var(--foreground)); text-underline-offset: 3px;"
            >Join Discord</a>
          </nav>
        </section>
      </main>
    </div>
    """
  end

  defp model_search_path(search) do
    query = String.trim(search)
    if query == "", do: "/", else: "/?q=#{URI.encode_www_form(query)}"
  end
end

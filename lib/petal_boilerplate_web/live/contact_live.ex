defmodule PetalBoilerplateWeb.ContactLive do
  use PetalBoilerplateWeb, :live_view

  alias PetalBoilerplateWeb.ModelMetadataFeedback
  alias PetalBoilerplateWeb.PublicRoutes
  alias PetalBoilerplateWeb.SEO

  @description "Contact routes for LLM Catalog support, model data corrections, security reports, privacy questions, and work with Jidoka Labs."

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Contact",
       page_description: @description,
       canonical_url: PublicRoutes.absolute("/contact"),
       structured_data: SEO.contact_structured_data(@description),
       metadata_issue_url: ModelMetadataFeedback.issue_url()
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

      <main class="flex-1 w-full max-w-3xl mx-auto py-10 sm:py-14 px-4 sm:px-6">
        <p class="text-sm font-semibold uppercase tracking-wide" style="color: hsl(var(--primary));">
          LLM Catalog by Jidoka Labs
        </p>
        <h1 class="mt-2 text-3xl font-bold sm:text-4xl" style="color: hsl(var(--foreground));">
          Contact LLM Catalog
        </h1>
        <p class="mt-4 max-w-2xl text-lg leading-8" style="color: hsl(var(--muted-foreground));">
          Choose the contact route that matches your request. LLM Catalog is an open-source public service, so public technical work is handled through GitHub when possible. Do not put secrets, credentials, private customer data, or sensitive personal data in a public issue.
        </p>

        <div class="mt-10 grid gap-6 sm:grid-cols-2">
          <.contact_card title="Incorrect model data">
            Report a wrong model identifier, price, capability, limit, or provider record with the structured <a
              class="link"
              href={@metadata_issue_url}
              target="_blank"
              rel="noopener noreferrer"
            >
              model metadata form
            </a>.
            Include a public provider source that supports the correction.
          </.contact_card>

          <.contact_card title="Site or API problem">
            Open an issue in the <a
              class="link"
              href="https://github.com/agentjido/llmcatalog/issues"
              target="_blank"
              rel="noopener noreferrer"
            >LLM Catalog repository</a>.
            Include the public URL, expected result, actual result, and a minimal reproduction.
          </.contact_card>

          <.contact_card title="Security or privacy">
            Use the private contact form on
            <a
              class="link"
              href="https://jidokahq.com/#contact"
              target="_blank"
              rel="noopener noreferrer"
            >
              Jidoka HQ
            </a>
            for a security report, privacy question, or other matter that must not be public. Do not demonstrate a vulnerability against production data.
          </.contact_card>

          <.contact_card title="Community support">
            Join the
            <a class="link" href="https://jido.run/discord" target="_blank" rel="noopener noreferrer">
              Jido Discord community
            </a>
            for public discussion about llmdb, LLM Catalog integrations, and the wider Jido ecosystem. GitHub remains the source of record for reproducible defects.
          </.contact_card>
        </div>

        <section class="mt-10 border-t pt-8" style="border-color: hsl(var(--border));">
          <h2 class="text-xl font-semibold" style="color: hsl(var(--foreground));">
            Response and service limits
          </h2>
          <p class="mt-3 leading-7" style="color: hsl(var(--muted-foreground));">
            LLM Catalog has no paid support plan or formal response-time agreement. Maintainers review clear, reproducible reports as capacity permits. Catalog values come from public sources and can lag a provider change. For an urgent production decision, confirm the value directly with the model provider instead of waiting for a catalog update.
          </p>
        </section>
      </main>
    </div>
    """
  end

  attr :title, :string, required: true
  slot :inner_block, required: true

  defp contact_card(assigns) do
    ~H"""
    <section
      class="rounded-lg border p-6"
      style="border-color: hsl(var(--border)); background-color: hsl(var(--card));"
    >
      <h2 class="text-lg font-semibold" style="color: hsl(var(--foreground));">{@title}</h2>
      <p class="mt-3 leading-7" style="color: hsl(var(--muted-foreground));">
        {render_slot(@inner_block)}
      </p>
    </section>
    """
  end
end

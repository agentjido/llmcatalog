defmodule PetalBoilerplateWeb.DevelopersLive do
  use PetalBoilerplateWeb, :live_view

  alias PetalBoilerplateWeb.PublicRoutes
  alias PetalBoilerplateWeb.SEO

  @description "Use the public data and developer interfaces from LLM Catalog by Jidoka Labs."

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Developer guide",
       page_description: @description,
       canonical_url: PublicRoutes.absolute("/developers"),
       structured_data: SEO.developers_structured_data(@description)
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

      <main class="flex-1 w-full max-w-4xl mx-auto py-8 sm:py-12 px-4 sm:px-6">
        <p class="text-sm font-semibold uppercase tracking-wide" style="color: hsl(var(--primary));">
          LLM Catalog by
          <a
            href="https://jidokahq.com/"
            target="_blank"
            rel="noopener noreferrer"
            class="hover:underline focus-visible:outline-2 focus-visible:outline-offset-2"
            style="text-underline-offset: 3px;"
          >Jidoka Labs</a>
        </p>
        <h1 class="mt-2 text-3xl sm:text-4xl font-bold" style="color: hsl(var(--foreground));">
          Developer guide
        </h1>
        <p class="mt-4 text-lg" style="color: hsl(var(--muted-foreground));">
          Use public catalog pages, Markdown copies, history APIs, and lookup tools without an API key.
        </p>

        <.section title="Choose the right interface">
          <ul class="space-y-3 list-disc pl-6" style="color: hsl(var(--muted-foreground));">
            <li>
              Use the <a class="link" href="/">catalog</a>
              when a person needs to browse, filter, or compare models.
            </li>
            <li>
              Use Markdown when an agent needs compact page content with stable headings and links.
            </li>
            <li>Use the history API when software needs model metadata changes as JSON.</li>
            <li>Use the npm package when a Node.js application needs the catalog data locally.</li>
            <li>
              Do not use this catalog as the only source for a purchase or production routing decision. Provider prices, limits, and availability can change.
            </li>
          </ul>
        </.section>

        <.section title="Markdown and discovery">
          <p style="color: hsl(var(--muted-foreground));">
            Send <code>Accept: text/markdown</code>
            to a supported public page, or add <code>.md</code>
            to its path. Use <a class="link" href="/llms.txt">/llms.txt</a>
            for retrieval guidance and <a class="link" href="/sitemap.xml">/sitemap.xml</a>
            for the public page list.
          </p>
          <.code>curl -H 'Accept: text/markdown' https://llmcatalog.dev/models/openai/gpt-4o</.code>
        </.section>

        <.section title="History API">
          <p style="color: hsl(var(--muted-foreground));">
            These read-only routes return JSON. The optional <code>limit</code>
            value must be from 1 through 1000.
          </p>
          <.code>GET /api/history/recent?limit=25
            GET /api/history/:provider/:model_id?limit=100</.code>
          <p class="mt-4" style="color: hsl(var(--muted-foreground));">
            See the <a class="link" href="/openapi.json">OpenAPI 3.1 document</a>
            for request and response schemas.
          </p>
        </.section>

        <.section title="Catalog lookup tools">
          <p style="color: hsl(var(--muted-foreground));">
            <code>POST /api/mcp</code>
            accepts the documented <code>tools/list</code>
            and <code>tools/call</code>
            request shapes. Available tools are <code>query_models</code>, <code>get_model</code>, and <code>list_providers</code>. This is a small tool interface.
            It is not a complete MCP protocol server.
          </p>
          <.code>curl https://llmcatalog.dev/api/mcp \
            -H 'content-type: application/json' \
            -d '&#123;"method":"tools/list"&#125;'</.code>
        </.section>

        <.section title="JavaScript package">
          <p style="color: hsl(var(--muted-foreground));">
            The official
            <a
              class="link"
              href="https://www.npmjs.com/package/@agentjido/llmdb"
              target="_blank"
              rel="noopener noreferrer"
            >@agentjido/llmdb package</a>
            provides the catalog for JavaScript and TypeScript applications.
            It requires Node.js 22.14 or later. The package does not currently install a command-line executable.
          </p>
          <.code>npm install @agentjido/llmdb

            import &#123; llmdb &#125; from "@agentjido/llmdb";
            const model = await llmdb.get("openai:gpt-5.4");</.code>
        </.section>

        <.section title="API errors" id="api-errors">
          <p style="color: hsl(var(--muted-foreground));">
            API failures use <code>application/problem+json</code>. Each response includes a stable <code>code</code>, HTTP <code>status</code>, human-readable <code>detail</code>, request <code>instance</code>, and a suggested <code>resolution</code>. Clients should branch on the code and status.
          </p>
        </.section>

        <.section title="Data and service limits">
          <p style="color: hsl(var(--muted-foreground));">
            Public interfaces have no authentication and no formal availability guarantee. Cache responses when practical.
            Check provider documentation before you depend on a price, feature, model name, or service limit.
          </p>
        </.section>
      </main>
    </div>
    """
  end

  attr :title, :string, required: true
  attr :id, :string, default: nil
  slot :inner_block, required: true

  defp section(assigns) do
    ~H"""
    <section
      id={@id}
      class="mt-8 rounded-lg border p-6"
      style="border-color: hsl(var(--border)); background-color: hsl(var(--card));"
    >
      <h2 class="text-xl font-semibold mb-4" style="color: hsl(var(--foreground));">
        {@title}
      </h2>
      {render_slot(@inner_block)}
    </section>
    """
  end

  slot :inner_block, required: true

  defp code(assigns) do
    ~H"""
    <pre
      class="mt-4 overflow-x-auto rounded-md p-4 text-sm"
      style="background-color: hsl(var(--secondary)); color: hsl(var(--secondary-foreground));"
    ><code>{render_slot(@inner_block)}</code></pre>
    """
  end
end

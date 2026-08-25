defmodule PetalBoilerplateWeb.PrivacyLive do
  use PetalBoilerplateWeb, :live_view

  alias PetalBoilerplateWeb.PublicRoutes
  alias PetalBoilerplateWeb.SEO

  @description "Privacy policy for LLM Catalog by Jidoka Labs."

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Privacy policy",
       page_description: @description,
       canonical_url: PublicRoutes.absolute("/privacy"),
       structured_data: SEO.privacy_structured_data(@description)
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
          Privacy policy
        </h1>
        <p class="mt-3 text-sm" style="color: hsl(var(--muted-foreground));">
          Effective August 25, 2026
        </p>

        <div class="mt-8 space-y-8" style="color: hsl(var(--muted-foreground));">
          <.policy_section title="Summary">
            LLM Catalog is a public website. It does not offer user accounts. We collect limited technical data to operate, secure, and improve the site. We do not sell personal data or use it for advertising.
          </.policy_section>

          <.policy_section title="Server data">
            Our hosting and application systems can process standard request data. This data can include an IP address, forwarded IP address, user agent, request path, request method, response status, request identifier, and request duration. We use this data for security, fault diagnosis, and service operation. Retention can vary with operational needs and hosting settings.
          </.policy_section>

          <.policy_section title="Plausible Analytics">
            When analytics are enabled, we use Plausible Analytics to measure page use and selected catalog actions. Plausible does not set cookies or use persistent identifiers. The browser sends events through first-party paths on this site. Search analytics use an exact catalog allowlist. If a full search matches a provider name or ID, model name, or model ID, we send its canonical catalog label. Every other search is recorded only as "other"; unmatched search text is not sent. Plausible is not enabled in the local development environment by default. See the
            <a
              class="link"
              href="https://plausible.io/data-policy"
              target="_blank"
              rel="noopener noreferrer"
            >Plausible data policy</a>
            for information about its service.
          </.policy_section>

          <.policy_section title="Cookies and browser storage">
            The site uses a signed session cookie for security and LiveView functions. It is required for these site functions and expires when the browser session ends. If you select a color theme, your browser stores that preference in local storage. We do not use cookies or local storage for analytics or advertising.
          </.policy_section>

          <.policy_section title="External services">
            Pages can request fonts from Google Fonts and JavaScript libraries from unpkg. If you open a link to another site, that site applies its own privacy policy. Our hosting provider and Plausible can process data for us as service providers.
          </.policy_section>

          <.policy_section title="Questions and changes">
            We can update this policy when the site or its services change. The effective date above shows the current version. For a privacy question, open an issue in the <a
              class="link"
              href="https://github.com/agentjido/llmcatalog/issues"
              target="_blank"
              rel="noopener noreferrer"
            >LLM Catalog GitHub repository</a>. Do not include sensitive personal data in a public issue.
          </.policy_section>
        </div>
      </main>
    </div>
    """
  end

  attr :title, :string, required: true
  slot :inner_block, required: true

  defp policy_section(assigns) do
    ~H"""
    <section>
      <h2 class="text-xl font-semibold mb-3" style="color: hsl(var(--foreground));">
        {@title}
      </h2>
      <p class="leading-7">{render_slot(@inner_block)}</p>
    </section>
    """
  end
end

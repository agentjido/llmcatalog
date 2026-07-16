defmodule PetalBoilerplateWeb.ModelComponents do
  use PetalBoilerplateWeb, :html

  alias PetalBoilerplate.Catalog
  alias PetalBoilerplate.Catalog.Filters
  alias PetalBoilerplateWeb.ModelLive

  # =============================================================================
  # Task 2.1: Header Component
  # =============================================================================

  defp llm_db_version do
    Application.spec(:llm_db, :vsn) |> to_string()
  end

  attr :search_value, :string, required: true

  def header(assigns) do
    ~H"""
    <header
      class="sticky top-0 z-50 border-b backdrop-blur supports-[backdrop-filter]:bg-[hsl(var(--background)/0.6)]"
      style="border-color: hsl(var(--border)); background-color: hsl(var(--background) / 0.95);"
    >
      <div class="w-full max-w-full flex h-14 items-center gap-3 px-4">
        <a
          href="/"
          aria-label="LLM Model DB home"
          class="flex items-center gap-2 shrink-0 transition-opacity hover:opacity-80"
          title="Go to home page"
        >
          <.icon name="hero-circle-stack" class="h-6 w-6" style="color: hsl(var(--primary));" />
          <span
            class="text-lg font-semibold tracking-tight hidden sm:inline"
            style="color: hsl(var(--foreground));"
          >
            LLM Model DB
          </span>
        </a>

        <div class="flex-1" />

        <form
          id="model-search-form"
          phx-change="filter"
          phx-debounce="300"
          class="w-full max-w-[200px] sm:max-w-xs md:max-w-sm"
        >
          <div class="relative">
            <.icon
              name="hero-magnifying-glass"
              class="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2"
              style="color: hsl(var(--muted-foreground));"
            />
            <input
              type="text"
              name="search"
              id="search-input"
              value={@search_value}
              placeholder="Search..."
              autofocus
              class="w-full pl-9 pr-9 h-9 rounded-md border-0 text-sm"
              style="background-color: hsl(var(--secondary)); color: hsl(var(--foreground));"
            />
            <button
              :if={@search_value != ""}
              type="button"
              phx-click={JS.push("clear_search") |> JS.focus(to: "#search-input")}
              onclick="document.getElementById('search-input').value = ''"
              class="absolute right-2 top-1/2 flex h-6 w-6 -translate-y-1/2 items-center justify-center rounded-md transition-colors hover:opacity-80"
              style="color: hsl(var(--muted-foreground));"
              aria-label="Clear search"
              title="Clear search"
            >
              <.icon name="hero-x-mark" class="h-4 w-4" />
            </button>
          </div>
        </form>

        <a
          href="https://hex.pm/packages/llm_db"
          target="_blank"
          rel="noopener noreferrer"
          class="text-xs hidden sm:flex items-center gap-1 px-2 py-1 rounded border transition-colors hover:opacity-80"
          style="color: hsl(var(--muted-foreground)); border-color: hsl(var(--border));"
          title="View llm_db package on Hex"
        >
          <.icon name="hero-cube" class="h-3 w-3" /> llm_db v{llm_db_version()}
        </a>

        <a
          href="/history"
          class="text-sm hidden sm:block transition-colors hover:opacity-80"
          style="color: hsl(var(--muted-foreground));"
        >
          History
        </a>

        <a
          href="/about"
          class="text-sm hidden sm:block transition-colors hover:opacity-80"
          style="color: hsl(var(--muted-foreground));"
        >
          About
        </a>

        <div class="flex items-center gap-0.5 shrink-0">
          <a
            href="https://agentjido.xyz/discord"
            target="_blank"
            rel="noopener noreferrer"
            title="Join Discord"
            aria-label="Join Discord"
            class="hidden sm:block p-2 rounded-md transition-colors hover:opacity-80"
            style="color: hsl(var(--foreground));"
          >
            <svg class="h-4 w-4" fill="currentColor" viewBox="0 0 24 24">
              <path d="M20.317 4.37a19.791 19.791 0 0 0-4.885-1.515.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 0 0-5.487 0 12.64 12.64 0 0 0-.617-1.25.077.077 0 0 0-.079-.037A19.736 19.736 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057 19.9 19.9 0 0 0 5.993 3.03.078.078 0 0 0 .084-.028 14.09 14.09 0 0 0 1.226-1.994.076.076 0 0 0-.041-.106 13.107 13.107 0 0 1-1.872-.892.077.077 0 0 1-.008-.128 10.2 10.2 0 0 0 .372-.292.074.074 0 0 1 .077-.01c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127 12.299 12.299 0 0 1-1.873.892.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028 19.839 19.839 0 0 0 6.002-3.03.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.956-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.956 2.418-2.157 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.955-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.946 2.418-2.157 2.418z" />
            </svg>
          </a>
          <a
            href="https://github.com/agentjido/llm_db"
            target="_blank"
            rel="noopener noreferrer"
            title="GitHub"
            aria-label="View llm_db on GitHub"
            class="hidden sm:block p-2 rounded-md transition-colors hover:opacity-80"
            style="color: hsl(var(--foreground));"
          >
            <svg class="h-4 w-4" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z" />
            </svg>
          </a>
          <button
            type="button"
            onclick="toggleScheme()"
            title="Toggle theme"
            aria-label="Toggle theme"
            class="p-2 rounded-md transition-colors hover:opacity-80"
            style="color: hsl(var(--foreground));"
          >
            <.icon name="hero-moon" class="h-4 w-4 color-scheme-dark-icon" />
            <.icon name="hero-sun" class="h-4 w-4 color-scheme-light-icon hidden" />
          </button>

          <details class="relative sm:hidden">
            <summary
              aria-label="Open navigation"
              class="flex list-none items-center justify-center p-2 rounded-md transition-colors hover:opacity-80 [&::-webkit-details-marker]:hidden"
              style="color: hsl(var(--foreground));"
            >
              <.icon name="hero-bars-3" class="h-4 w-4" />
            </summary>
            <nav
              aria-label="Mobile navigation"
              class="absolute right-0 top-full mt-2 w-48 overflow-hidden rounded-md border shadow-lg"
              style="border-color: hsl(var(--border)); background-color: hsl(var(--popover)); color: hsl(var(--popover-foreground));"
            >
              <a href="/" class="block px-4 py-2.5 text-sm hover:opacity-80">Models</a>
              <a href="/history" class="block px-4 py-2.5 text-sm hover:opacity-80">History</a>
              <a href="/about" class="block px-4 py-2.5 text-sm hover:opacity-80">About</a>
              <a
                href="https://hex.pm/packages/llm_db"
                target="_blank"
                rel="noopener noreferrer"
                class="block px-4 py-2.5 text-sm hover:opacity-80"
              >
                llm_db v{llm_db_version()}
              </a>
              <a
                href="https://github.com/agentjido/llm_db"
                target="_blank"
                rel="noopener noreferrer"
                class="block px-4 py-2.5 text-sm hover:opacity-80"
              >
                GitHub
              </a>
              <a
                href="https://agentjido.xyz/discord"
                target="_blank"
                rel="noopener noreferrer"
                class="block px-4 py-2.5 text-sm hover:opacity-80"
              >
                Discord
              </a>
            </nav>
          </details>
        </div>
      </div>
    </header>
    """
  end

  # =============================================================================
  # Task 2.2: Capability Badge Component
  # =============================================================================

  @capability_colors %{
    chat: "--cap-chat",
    tools: "--cap-tools",
    vision: "--cap-vision",
    reasoning: "--cap-reason",
    streaming: "--cap-stream",
    embeddings: "--cap-embed",
    batch: "--cap-tools",
    citations: "--cap-stream",
    code_execution: "--cap-embed",
    context_management: "--cap-vision",
    json_output: "--muted-foreground",
    audio_input: "--cap-stream",
    audio_output: "--cap-stream",
    image_generation: "--cap-vision"
  }

  @capability_labels %{
    chat: "Chat",
    tools: "Tools",
    vision: "Vision",
    reasoning: "Reasoning",
    streaming: "Streaming",
    embeddings: "Embed",
    batch: "Batch",
    citations: "Cite",
    code_execution: "Code",
    context_management: "Ctx",
    json_output: "JSON",
    audio_input: "Audio In",
    audio_output: "Audio Out",
    image_generation: "Image Gen"
  }

  @capability_icons %{
    chat: "hero-chat-bubble-left",
    tools: "hero-wrench",
    vision: "hero-eye",
    reasoning: "hero-academic-cap",
    streaming: "hero-bolt",
    embeddings: "hero-hashtag",
    batch: "hero-arrows-right-left",
    citations: "hero-document-text",
    code_execution: "hero-code-bracket",
    context_management: "hero-circle-stack",
    json_output: "hero-code-bracket",
    audio_input: "hero-microphone",
    audio_output: "hero-speaker-wave",
    image_generation: "hero-photo"
  }

  attr :capability, :atom, required: true
  attr :active, :boolean, default: true
  attr :compact, :boolean, default: false

  def capability_badge(assigns) do
    color_var = Map.get(@capability_colors, assigns.capability, "--muted-foreground")
    label = Map.get(@capability_labels, assigns.capability, to_string(assigns.capability))
    icon_name = Map.get(@capability_icons, assigns.capability)

    assigns =
      assigns
      |> assign(:color_var, color_var)
      |> assign(:label, label)
      |> assign(:icon_name, icon_name)

    ~H"""
    <span
      :if={@active}
      class={"inline-flex items-center gap-1 rounded border font-medium #{if @compact, do: "px-1.5 py-0.5 text-[10px]", else: "px-2 py-0.5 text-xs"}"}
      style={"background-color: hsl(var(#{@color_var}) / 0.2); color: hsl(var(#{@color_var})); border-color: hsl(var(#{@color_var}) / 0.3);"}
    >
      <.icon :if={@icon_name} name={@icon_name} class="h-2.5 w-2.5" />
      {@label}
    </span>
    """
  end

  # =============================================================================
  # Task 2.3: Filter Bar Component
  # =============================================================================

  attr :filters, :any, required: true
  attr :providers, :list, required: true
  attr :active_quick_filters, :list, default: []
  attr :filters_open, :boolean, required: true

  def filter_bar(assigns) do
    quick_filters = Filters.quick_filters()
    assigns = assign(assigns, :quick_filters, quick_filters)

    ~H"""
    <div
      class="sticky top-14 z-40 border-b backdrop-blur supports-[backdrop-filter]:bg-[hsl(var(--background)/0.8)]"
      style="border-color: hsl(var(--border)); background-color: hsl(var(--background) / 0.95);"
    >
      <div class="hidden md:block">
        <div class="w-full max-w-full py-2.5 px-4">
          <div class="flex items-center gap-3">
            <span class="text-sm shrink-0 font-medium" style="color: hsl(var(--muted-foreground));">
              Quick:
            </span>
            <div class="flex items-center gap-2 flex-wrap">
              <%= for qf <- @quick_filters do %>
                <.quick_filter_pill
                  label={qf.label}
                  icon={qf.icon}
                  kind={to_string(qf.key)}
                  active={qf.key in @active_quick_filters}
                />
              <% end %>
            </div>
          </div>
        </div>

        <div class="w-full max-w-full pb-2.5 px-4">
          <div class="flex items-center gap-2">
            <.icon
              name="hero-funnel"
              class="h-4 w-4 shrink-0"
              style="color: hsl(var(--muted-foreground));"
            />

            <.filter_dropdown
              id="filter-provider"
              label={"Provider #{provider_count_label(@filters)}"}
              active={MapSet.size(@filters.provider_ids) > 0}
            >
              <.provider_filter_content
                providers={@providers}
                filters={@filters}
                form_id="provider-search-form"
              />
            </.filter_dropdown>

            <.filter_dropdown
              id="filter-capabilities"
              label="Capabilities"
              active={has_capability_filters?(@filters.capabilities)}
            >
              <.capabilities_filter_content
                filters={@filters}
                form_id="capabilities-filter-form"
              />
            </.filter_dropdown>

            <.filter_dropdown
              id="filter-modalities-in"
              label={"Input #{modality_count_label(@filters.modalities_in)}"}
              active={MapSet.size(@filters.modalities_in) > 0}
            >
              <.modalities_filter_content
                filters={@filters}
                direction={:input}
                form_id="input-modalities-filter-form"
              />
            </.filter_dropdown>

            <.filter_dropdown
              id="filter-modalities-out"
              label={"Output #{modality_count_label(@filters.modalities_out)}"}
              active={MapSet.size(@filters.modalities_out) > 0}
            >
              <.modalities_filter_content
                filters={@filters}
                direction={:output}
                form_id="output-modalities-filter-form"
              />
            </.filter_dropdown>

            <.filter_dropdown
              id="filter-context"
              label={"Context #{context_label(@filters)}"}
              active={@filters.min_context != nil}
            >
              <.context_filter_content filters={@filters} />
            </.filter_dropdown>

            <.filter_dropdown
              id="filter-cost"
              label={"Cost #{cost_label(@filters)}"}
              active={@filters.max_cost_in != nil or @filters.max_cost_out != nil}
            >
              <.cost_filter_content filters={@filters} />
            </.filter_dropdown>

            <div class="flex flex-wrap gap-1 ml-2 overflow-x-auto scrollbar-none">
              <%= for chip <- active_filter_chips(@filters, @providers) do %>
                <.filter_chip label={chip.label} kind={chip.kind} filter_value={chip.value} />
              <% end %>
            </div>

            <button
              :if={has_active_filters?(@filters)}
              type="button"
              phx-click="clear_filters"
              class="ml-auto h-8 px-3 text-sm transition-colors hover:opacity-80"
              style="color: hsl(var(--muted-foreground));"
            >
              Clear filters
            </button>
          </div>
        </div>
      </div>

      <div class="md:hidden">
        <div class="w-full max-w-full py-2.5 px-4">
          <div class="flex items-center gap-2">
            <button
              id="mobile-filters-trigger"
              type="button"
              phx-click={JS.push_focus() |> JS.push("toggle_filters")}
              aria-expanded={to_string(@filters_open)}
              aria-controls="mobile-filters-dialog"
              class="h-9 px-3 flex items-center gap-2 rounded-md border text-sm"
              style="border-color: hsl(var(--border));"
            >
              <.icon name="hero-adjustments-horizontal" class="h-4 w-4" /> Filters
              <span
                :if={filter_count(@filters) > 0}
                class="h-5 min-w-5 px-1.5 text-xs rounded-full flex items-center justify-center"
                style="background-color: hsl(var(--secondary)); color: hsl(var(--secondary-foreground));"
              >
                {filter_count(@filters)}
              </span>
            </button>

            <div class="flex items-center gap-1.5 overflow-x-auto scrollbar-none flex-1">
              <%= for chip <- active_filter_chips(@filters, @providers) do %>
                <.filter_chip label={chip.label} kind={chip.kind} filter_value={chip.value} />
              <% end %>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div
      :if={@filters_open}
      class="fixed inset-0 top-14 z-[60] md:hidden"
      phx-remove={JS.pop_focus()}
    >
      <button
        type="button"
        phx-click="toggle_filters"
        class="absolute inset-0 bg-black/50 backdrop-blur-sm"
        aria-label="Close filters"
      ></button>
      <.focus_wrap
        id="mobile-filters-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby="mobile-filters-title"
        phx-mounted={JS.focus_first(to: "#mobile-filters-dialog")}
        phx-window-keydown="toggle_filters"
        phx-key="escape"
        class="absolute inset-y-0 left-0 w-[min(90vw,24rem)] overflow-y-auto border-r shadow-xl"
        style="border-color: hsl(var(--border)); background-color: hsl(var(--background));"
      >
        <div
          class="sticky top-0 z-10 flex items-center justify-between border-b px-4 py-3"
          style="border-color: hsl(var(--border)); background-color: hsl(var(--background));"
        >
          <h2 id="mobile-filters-title" class="text-lg font-semibold">Filters</h2>
          <button
            type="button"
            phx-click="toggle_filters"
            class="p-2 rounded-md hover:opacity-80"
            aria-label="Close filters"
            autofocus
          >
            <.icon name="hero-x-mark" class="h-5 w-5" />
          </button>
        </div>

        <div class="space-y-5 p-4 pb-10">
          <section aria-labelledby="mobile-quick-filters-title">
            <h3 id="mobile-quick-filters-title" class="mb-2 text-sm font-semibold">
              Quick filters
            </h3>
            <div class="flex flex-wrap gap-2">
              <%= for qf <- @quick_filters do %>
                <.quick_filter_pill
                  label={qf.label}
                  icon={qf.icon}
                  kind={to_string(qf.key)}
                  active={qf.key in @active_quick_filters}
                />
              <% end %>
            </div>
          </section>

          <section aria-labelledby="mobile-provider-filters-title">
            <h3 id="mobile-provider-filters-title" class="text-sm font-semibold">Providers</h3>
            <div class="mt-2 overflow-hidden rounded-md border">
              <.provider_filter_content
                providers={@providers}
                filters={@filters}
                form_id="mobile-provider-search-form"
              />
            </div>
          </section>

          <section aria-labelledby="mobile-capability-filters-title">
            <h3 id="mobile-capability-filters-title" class="text-sm font-semibold">
              Capabilities
            </h3>
            <div class="mt-2 overflow-hidden rounded-md border">
              <.capabilities_filter_content
                filters={@filters}
                form_id="mobile-capabilities-filter-form"
              />
            </div>
          </section>

          <section aria-labelledby="mobile-input-filters-title">
            <h3 id="mobile-input-filters-title" class="text-sm font-semibold">
              Input modalities
            </h3>
            <div class="mt-2 overflow-hidden rounded-md border">
              <.modalities_filter_content
                filters={@filters}
                direction={:input}
                form_id="mobile-input-modalities-filter-form"
              />
            </div>
          </section>

          <section aria-labelledby="mobile-output-filters-title">
            <h3 id="mobile-output-filters-title" class="text-sm font-semibold">
              Output modalities
            </h3>
            <div class="mt-2 overflow-hidden rounded-md border">
              <.modalities_filter_content
                filters={@filters}
                direction={:output}
                form_id="mobile-output-modalities-filter-form"
              />
            </div>
          </section>

          <section aria-labelledby="mobile-context-filters-title">
            <h3 id="mobile-context-filters-title" class="text-sm font-semibold">
              Context window
            </h3>
            <div class="mt-2 overflow-hidden rounded-md border">
              <.context_filter_content filters={@filters} />
            </div>
          </section>

          <section aria-labelledby="mobile-cost-filters-title">
            <h3 id="mobile-cost-filters-title" class="text-sm font-semibold">Input cost</h3>
            <div class="mt-2 overflow-hidden rounded-md border">
              <.cost_filter_content filters={@filters} />
            </div>
          </section>

          <button
            :if={has_active_filters?(@filters)}
            type="button"
            phx-click="clear_filters"
            class="w-full rounded-md border px-4 py-2 text-sm font-medium"
          >
            Clear all filters
          </button>
        </div>
      </.focus_wrap>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :icon, :string, required: true
  attr :kind, :string, required: true
  attr :active, :boolean, default: false

  defp quick_filter_pill(assigns) do
    ~H"""
    <button
      type="button"
      phx-click="quick_filter"
      phx-value-kind={@kind}
      class={"inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-sm font-medium transition-colors #{if @active, do: "", else: "hover:opacity-80"}"}
      style={
        if @active,
          do: "background-color: hsl(var(--primary)); color: hsl(var(--primary-foreground));",
          else: "background-color: hsl(var(--muted)); color: hsl(var(--muted-foreground));"
      }
    >
      <.icon name={@icon} class="h-4 w-4" />
      <span>{@label}</span>
    </button>
    """
  end

  attr :id, :string, required: true
  attr :label, :string, required: true
  attr :active, :boolean, default: false
  slot :inner_block, required: true

  defp filter_dropdown(assigns) do
    ~H"""
    <div class="relative">
      <button
        type="button"
        phx-click={JS.toggle(to: "##{@id}-panel")}
        class="h-8 px-3 text-sm rounded-md border flex items-center gap-1 transition-colors hover:opacity-80"
        style={
          if @active,
            do:
              "border-color: hsl(var(--primary)); background-color: hsl(var(--primary) / 0.1); color: hsl(var(--primary));",
            else: "border-color: hsl(var(--border)); background-color: hsl(var(--background));"
        }
      >
        {@label}
        <.icon
          name="hero-chevron-down"
          class="h-3 w-3"
          style={
            if @active,
              do: "color: hsl(var(--primary));",
              else: "color: hsl(var(--muted-foreground));"
          }
        />
      </button>
      <div
        id={"#{@id}-panel"}
        phx-click-away={JS.hide(to: "##{@id}-panel")}
        class="absolute left-0 top-full mt-1 hidden rounded-md border shadow-lg z-50"
        style="border-color: hsl(var(--border)); background-color: hsl(var(--popover)); color: hsl(var(--popover-foreground));"
      >
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  attr :providers, :list, required: true
  attr :filters, :map, required: true
  attr :form_id, :string, required: true

  defp provider_filter_content(assigns) do
    ~H"""
    <div class="w-64">
      <div class="p-2 border-b" style="border-color: hsl(var(--border));">
        <div class="relative">
          <.icon
            name="hero-magnifying-glass"
            class="absolute left-2 top-1/2 -translate-y-1/2 h-3.5 w-3.5"
            style="color: hsl(var(--muted-foreground));"
          />
          <form id={@form_id} phx-change="provider_search" phx-debounce="200">
            <input
              type="text"
              name="provider_search"
              value={@filters.provider_search}
              placeholder="Search providers..."
              class="h-8 w-full pl-7 text-sm rounded-md border-0"
              style="background-color: hsl(var(--secondary));"
            />
          </form>
        </div>
      </div>
      <div
        class="flex gap-1 p-2 border-b"
        style="border-color: hsl(var(--border)); background-color: hsl(var(--muted) / 0.3);"
      >
        <button
          type="button"
          phx-click="select_all_providers"
          class="h-6 flex-1 text-xs rounded hover:opacity-80"
        >
          Select All
        </button>
        <button
          type="button"
          phx-click="clear_providers"
          class="h-6 flex-1 text-xs rounded hover:opacity-80"
          disabled={MapSet.size(@filters.provider_ids) == 0}
        >
          Clear ({MapSet.size(@filters.provider_ids)})
        </button>
      </div>
      <div class="max-h-[280px] overflow-y-auto p-1">
        <%= for provider <- filtered_providers(@providers, @filters.provider_search) do %>
          <button
            type="button"
            role="checkbox"
            aria-checked={to_string(MapSet.member?(@filters.provider_ids, to_string(provider.id)))}
            class="flex w-full items-center gap-2 cursor-pointer rounded px-2 py-1.5 text-left hover:opacity-80"
            style="background-color: transparent;"
            onmouseover="this.style.backgroundColor='hsl(var(--accent))'"
            onmouseout="this.style.backgroundColor='transparent'"
            phx-click="toggle_provider"
            phx-value-id={provider.id}
          >
            <span
              aria-hidden="true"
              class="flex h-4 w-4 shrink-0 items-center justify-center rounded border"
              style="border-color: hsl(var(--border));"
            >
              <.icon
                :if={MapSet.member?(@filters.provider_ids, to_string(provider.id))}
                name="hero-check"
                class="h-3 w-3"
              />
            </span>
            <span class="text-sm truncate">{provider.name}</span>
          </button>
        <% end %>
      </div>
    </div>
    """
  end

  attr :filters, :map, required: true
  attr :form_id, :string, required: true

  defp capabilities_filter_content(assigns) do
    capabilities = [
      {:chat, "Chat"},
      {:tools, "Tools"},
      {:streaming_text, "Streaming"},
      {:reasoning, "Reasoning"},
      {:embeddings, "Embeddings"},
      {:json_native, "JSON Output"},
      {:batch, "Batch"},
      {:citations, "Citations"},
      {:code_execution, "Code Execution"},
      {:context_management, "Context Management"}
    ]

    assigns = assign(assigns, :capabilities, capabilities)

    ~H"""
    <div class="w-56 p-2">
      <form id={@form_id} phx-change="filter">
        <%= for {cap_key, cap_label} <- @capabilities do %>
          <label
            class="flex items-center gap-2 cursor-pointer rounded px-2 py-1 hover:opacity-80"
            style="background-color: transparent;"
            onmouseover="this.style.backgroundColor='hsl(var(--accent))'"
            onmouseout="this.style.backgroundColor='transparent'"
          >
            <input
              type="checkbox"
              name={"cap_#{cap_key}"}
              value="true"
              checked={get_capability_filter(@filters.capabilities, cap_key)}
              class="rounded"
              style="border-color: hsl(var(--border));"
            />
            <span class="text-sm">{cap_label}</span>
          </label>
        <% end %>
      </form>
    </div>
    """
  end

  @input_modality_options [
    {:text, "Text"},
    {:image, "Image"},
    {:file, "File"},
    {:pdf, "PDF"},
    {:audio, "Audio"},
    {:video, "Video"}
  ]

  @output_modality_options [
    {:text, "Text"},
    {:image, "Image"},
    {:audio, "Audio"},
    {:video, "Video"},
    {:embedding, "Embeddings"}
  ]

  attr :filters, :map, required: true
  attr :direction, :atom, values: [:input, :output], required: true
  attr :form_id, :string, required: true

  defp modalities_filter_content(assigns) do
    assigns =
      assigns
      |> assign(:param_key, modality_param_key(assigns.direction))
      |> assign(:selected_modalities, selected_modalities(assigns.filters, assigns.direction))
      |> assign(:modality_options, modality_options(assigns.direction))

    ~H"""
    <div class="w-48 p-2">
      <form id={@form_id} phx-change="filter">
        <%= for {modality_key, label} <- @modality_options do %>
          <label
            class="flex items-center gap-2 cursor-pointer rounded px-2 py-1 hover:opacity-80"
            style="background-color: transparent;"
            onmouseover="this.style.backgroundColor='hsl(var(--accent))'"
            onmouseout="this.style.backgroundColor='transparent'"
          >
            <input
              type="checkbox"
              name={"#{@param_key}[#{modality_key}]"}
              value="true"
              checked={MapSet.member?(@selected_modalities, modality_key)}
              class="rounded"
              style="border-color: hsl(var(--border));"
            />
            <span class="text-sm">{label}</span>
          </label>
        <% end %>
      </form>
    </div>
    """
  end

  attr :filters, :map, required: true

  defp context_filter_content(assigns) do
    context_options = [
      {0, "Any"},
      {8000, "8K+"},
      {32000, "32K+"},
      {100_000, "100K+"},
      {200_000, "200K+"},
      {1_000_000, "1M+"}
    ]

    assigns = assign(assigns, :context_options, context_options)

    ~H"""
    <div class="w-48 p-3">
      <div class="text-xs font-medium mb-2">Minimum context window</div>
      <div class="grid grid-cols-3 gap-1">
        <%= for {val, label} <- @context_options do %>
          <button
            type="button"
            phx-click="set_min_context"
            phx-value-value={val}
            class="px-2 py-1.5 text-xs rounded transition-colors cursor-pointer text-center"
            style={
              if @filters.min_context == val,
                do: "background-color: hsl(var(--primary)); color: hsl(var(--primary-foreground));",
                else: "background-color: hsl(var(--muted));"
            }
          >
            {label}
          </button>
        <% end %>
      </div>
    </div>
    """
  end

  attr :filters, :map, required: true

  defp cost_filter_content(assigns) do
    cost_options = [
      {0.5, "<$0.50"},
      {1, "<$1"},
      {3, "<$3"},
      {10, "<$10"},
      {50, "<$50"},
      {nil, "Any"}
    ]

    assigns = assign(assigns, :cost_options, cost_options)

    ~H"""
    <div class="w-48 p-3">
      <div class="text-xs font-medium mb-2">Max input cost (per 1M tokens)</div>
      <div class="grid grid-cols-2 gap-1">
        <%= for {val, label} <- @cost_options do %>
          <button
            type="button"
            phx-click="set_max_cost"
            phx-value-value={val || ""}
            class="px-2 py-1.5 text-xs rounded transition-colors cursor-pointer text-center"
            style={
              if @filters.max_cost_in == val,
                do: "background-color: hsl(var(--primary)); color: hsl(var(--primary-foreground));",
                else: "background-color: hsl(var(--muted));"
            }
          >
            {label}
          </button>
        <% end %>
      </div>
    </div>
    """
  end

  defp provider_count_label(filters) do
    count = MapSet.size(filters.provider_ids)
    if count > 0, do: "(#{count})", else: ""
  end

  defp modality_count_label(modalities) do
    count = MapSet.size(modalities)
    if count > 0, do: "(#{count})", else: ""
  end

  defp context_label(filters) do
    if filters.min_context && filters.min_context > 0 do
      "(>#{div(filters.min_context, 1000)}K)"
    else
      ""
    end
  end

  defp cost_label(filters) do
    if filters.max_cost_in && filters.max_cost_in < 100 do
      "(<$#{filters.max_cost_in})"
    else
      ""
    end
  end

  defp selected_provider_badges(filters, providers) do
    Enum.filter(providers, &MapSet.member?(filters.provider_ids, to_string(&1.id)))
  end

  defp has_active_filters?(filters) do
    MapSet.size(filters.provider_ids) > 0 ||
      is_integer(filters.changed_within_days) ||
      (filters.min_context != nil && filters.min_context > 0) ||
      filters.min_output != nil ||
      filters.max_cost_in != nil ||
      filters.max_cost_out != nil ||
      has_capability_filters?(filters.capabilities) ||
      MapSet.size(filters.modalities_in) > 0 ||
      MapSet.size(filters.modalities_out) > 0 ||
      filters.show_deprecated ||
      not filters.allowed_only
  end

  defp has_capability_filters?(capabilities) do
    Enum.any?(
      [
        :chat,
        :tools,
        :reasoning,
        :embeddings,
        :json_native,
        :streaming_text,
        :batch,
        :citations,
        :code_execution,
        :context_management
      ],
      fn cap ->
        get_capability_filter(capabilities, cap)
      end
    )
  end

  defp get_capability_filter(capabilities, key) when is_map(capabilities) do
    Map.get(capabilities, key, false)
  end

  defp get_capability_filter(_, _), do: false

  attr :label, :string, required: true
  attr :kind, :string, required: true
  attr :filter_value, :string, default: nil

  defp filter_chip(assigns) do
    ~H"""
    <span
      class="inline-flex items-center gap-1 h-6 px-2 text-xs rounded-md shrink-0"
      style="background-color: hsl(var(--primary) / 0.15); color: hsl(var(--primary)); border: 1px solid hsl(var(--primary) / 0.3);"
    >
      {@label}
      <button
        type="button"
        phx-click="remove_filter"
        phx-value-kind={@kind}
        phx-value-filter_value={@filter_value}
        class="hover:opacity-70 ml-0.5"
        aria-label={"Remove #{@label} filter"}
      >
        <.icon name="hero-x-mark" class="h-3 w-3" />
      </button>
    </span>
    """
  end

  defp active_filter_chips(filters, providers) do
    chips = []

    chips =
      chips ++
        Enum.map(selected_provider_badges(filters, providers), fn provider ->
          %{label: provider.name, kind: "provider", value: provider.id}
        end)

    chips =
      chips ++
        (filters.capabilities
         |> Enum.filter(fn {_k, v} -> v end)
         |> Enum.map(fn {k, _v} ->
           %{label: capability_chip_label(k), kind: "capability", value: to_string(k)}
         end))

    chips =
      chips ++
        (filters.modalities_in
         |> MapSet.to_list()
         |> Enum.sort_by(&modality_sort_key/1)
         |> Enum.map(fn mod ->
           %{label: "In: #{mod_label(mod)}", kind: "modality_in", value: to_string(mod)}
         end))

    chips =
      chips ++
        (filters.modalities_out
         |> MapSet.to_list()
         |> Enum.sort_by(&modality_sort_key/1)
         |> Enum.map(fn mod ->
           %{label: "Out: #{mod_label(mod)}", kind: "modality_out", value: to_string(mod)}
         end))

    chips =
      if is_integer(filters.changed_within_days) do
        chips ++
          [
            %{
              label: "Changed in #{filters.changed_within_days}d",
              kind: "changed_within",
              value: nil
            }
          ]
      else
        chips
      end

    chips =
      if filters.min_context && filters.min_context > 0 do
        chips ++
          [
            %{
              label: "Ctx ≥ #{format_context(filters.min_context)}",
              kind: "min_context",
              value: nil
            }
          ]
      else
        chips
      end

    chips =
      if filters.min_output && filters.min_output > 0 do
        chips ++
          [
            %{
              label: "Out ≥ #{format_context(filters.min_output)}",
              kind: "min_output",
              value: nil
            }
          ]
      else
        chips
      end

    chips =
      if filters.max_cost_in do
        chips ++
          [%{label: "In ≤ $#{filters.max_cost_in}/M", kind: "max_cost_in", value: nil}]
      else
        chips
      end

    chips =
      if filters.max_cost_out do
        chips ++
          [%{label: "Out ≤ $#{filters.max_cost_out}/M", kind: "max_cost_out", value: nil}]
      else
        chips
      end

    chips =
      if filters.show_deprecated do
        chips ++ [%{label: "Deprecated", kind: "show_deprecated", value: nil}]
      else
        chips
      end

    chips =
      if not filters.allowed_only do
        chips ++ [%{label: "Include disallowed", kind: "allowed_only", value: nil}]
      else
        chips
      end

    chips
  end

  defp capability_chip_label(cap) do
    case cap do
      :chat -> "Chat"
      :tools -> "Tools"
      :vision -> "Vision"
      :reasoning -> "Reasoning"
      :embeddings -> "Embeddings"
      :json_native -> "JSON"
      :streaming_text -> "Streaming"
      :batch -> "Batch"
      :citations -> "Citations"
      :code_execution -> "Code"
      :context_management -> "Context"
      other -> to_string(other) |> String.capitalize()
    end
  end

  defp mod_label(mod) do
    case mod do
      :text -> "Text"
      :image -> "Image"
      :file -> "File"
      :pdf -> "PDF"
      :audio -> "Audio"
      :video -> "Video"
      :embedding -> "Embeddings"
      other -> to_string(other) |> String.capitalize()
    end
  end

  defp modality_options(:input), do: @input_modality_options
  defp modality_options(:output), do: @output_modality_options

  defp modality_param_key(:input), do: "modalities_in"
  defp modality_param_key(:output), do: "modalities_out"

  defp selected_modalities(filters, :input), do: filters.modalities_in
  defp selected_modalities(filters, :output), do: filters.modalities_out

  defp modality_sort_key(modality) do
    case modality do
      :text -> 0
      :image -> 1
      :file -> 2
      :pdf -> 3
      :audio -> 4
      :video -> 5
      :embedding -> 6
      _ -> 99
    end
  end

  defp format_context(value) when value >= 1_000_000, do: "#{div(value, 1_000_000)}M"
  defp format_context(value) when value >= 1000, do: "#{div(value, 1000)}K"
  defp format_context(value), do: to_string(value)

  defp filter_count(%Filters{} = filters) do
    filters
    |> Filters.active_filter_count()
    |> count_without_search(filters.search)
  end

  defp filter_count(filters) when is_map(filters) do
    filters
    |> Catalog.active_filter_count()
    |> count_without_search(Map.get(filters, :search, ""))
  end

  defp count_without_search(count, ""), do: count
  defp count_without_search(count, _search), do: max(count - 1, 0)

  # =============================================================================
  # Task 2.4: Model Table Component
  # =============================================================================

  attr :models, :any, required: true
  attr :sort, :map, required: true
  attr :total, :integer, required: true
  attr :selected_ids, :any, default: MapSet.new()
  attr :can_add_more, :boolean, default: true

  def model_table(assigns) do
    ~H"""
    <div class="overflow-x-auto scrollbar-thin">
      <table class="w-full text-sm hidden md:table">
        <thead style="background-color: hsl(var(--table-header));">
          <tr class="border-b" style="border-color: hsl(var(--table-border));">
            <th class="w-10 px-3 py-3 text-left"></th>
            <.sortable_header field={:provider} label="Provider" sort={@sort} />
            <.sortable_header field={:name} label="Model" sort={@sort} />
            <th class="px-3 py-3 text-left font-medium" style="color: hsl(var(--muted-foreground));">
              I/O
            </th>
            <th class="px-3 py-3 text-left font-medium" style="color: hsl(var(--muted-foreground));">
              Features
            </th>
            <.sortable_header field={:context} label="Context" sort={@sort} align="right" />
            <.sortable_header field={:cost_in} label="In/Out $/M" sort={@sort} align="right" />
          </tr>
        </thead>
        <tbody :if={@total == 0} id="models-table-empty-body">
          <tr id="no-models-row">
            <td
              colspan="7"
              class="px-3 py-12 text-center"
              style="color: hsl(var(--muted-foreground));"
            >
              No models match your filters
            </td>
          </tr>
        </tbody>
        <tbody :if={@total > 0} id="models-table-body">
          <tr
            :for={model <- @models}
            id={model.id}
            phx-click="show_model"
            phx-value-id={model.id}
            class="border-b cursor-pointer transition-colors"
            style={"border-color: hsl(var(--table-border)); #{if MapSet.member?(@selected_ids, model.id), do: "background-color: hsl(var(--table-row-selected));", else: ""}"}
            onmouseover={
              if !MapSet.member?(@selected_ids, model.id),
                do: "this.style.backgroundColor='hsl(var(--table-row-hover))'"
            }
            onmouseout={
              if !MapSet.member?(@selected_ids, model.id),
                do: "this.style.backgroundColor='transparent'"
            }
          >
            <td class="px-3 py-2">
              <input
                id={"compare-desktop-#{model.id}"}
                type="checkbox"
                checked={MapSet.member?(@selected_ids, model.id)}
                disabled={!MapSet.member?(@selected_ids, model.id) && !@can_add_more}
                phx-click="toggle_select"
                phx-value-id={model.id}
                class="rounded"
                style="border-color: hsl(var(--border));"
                aria-label={"Select #{model.name} for comparison"}
              />
            </td>
            <td class="px-3 py-2" style="color: hsl(var(--muted-foreground));">
              {model.provider}
            </td>
            <td class="px-3 py-2">
              <div class="flex items-center gap-2">
                <div>
                  <.link
                    patch={model_detail_path(model)}
                    class="font-medium hover:underline"
                  >
                    {model.name}
                  </.link>
                  <div class="text-xs font-mono" style="color: hsl(var(--muted-foreground));">
                    {model.model_id}
                    <span :if={model.__last_changed_at}>
                      {" • Updated "}
                      {String.slice(model.__last_changed_at, 0, 10)}
                    </span>
                  </div>
                </div>
                <%= if model.deprecated || lifecycle_status(model) != "active" do %>
                  <span
                    class="text-[10px] px-1 py-0 rounded"
                    style="background-color: hsl(var(--destructive) / 0.1); color: hsl(var(--destructive));"
                  >
                    {lifecycle_label(model)}
                  </span>
                <% end %>
              </div>
            </td>
            <td class="px-3 py-2">
              <.modality_badges model={model} />
            </td>
            <td class="px-3 py-2">
              <div class="flex flex-wrap gap-1">
                <.capability_badge
                  :if={model_has_capability?(model, :reasoning)}
                  capability={:reasoning}
                  compact
                />
                <.capability_badge
                  :if={model_has_capability?(model, :tools)}
                  capability={:tools}
                  compact
                />
                <.capability_badge
                  :if={model_has_capability?(model, :batch)}
                  capability={:batch}
                  compact
                />
                <.capability_badge
                  :if={model_has_capability?(model, :code_execution)}
                  capability={:code_execution}
                  compact
                />
                <.capability_badge :if={has_vision?(model)} capability={:vision} compact />
                <.capability_badge
                  :if={embeddings_enabled?(model.capabilities)}
                  capability={:embeddings}
                  compact
                />
                <.capability_badge
                  :if={model_has_capability?(model, :json_output)}
                  capability={:json_output}
                  compact
                />
              </div>
            </td>
            <td class="px-3 py-2 text-right font-mono text-xs">
              {ModelLive.format_number(model_limit(model, :context))}
            </td>
            <td class="px-3 py-2 text-right font-mono text-xs">
              {ModelLive.format_cost(model_cost(model, :input))}/{ModelLive.format_cost(
                model_cost(model, :output)
              )}
            </td>
          </tr>
        </tbody>
      </table>

      <div class="md:hidden divide-y" style="border-color: hsl(var(--border));">
        <%= if @total == 0 do %>
          <div class="py-12 text-center" style="color: hsl(var(--muted-foreground));">
            No models match your filters
          </div>
        <% else %>
          <div
            :for={model <- @models}
            id={"mobile-#{model.id}"}
            class="p-3 transition-colors cursor-pointer"
            style={
              if MapSet.member?(@selected_ids, model.id),
                do: "background-color: hsl(var(--table-row-selected));",
                else: ""
            }
            phx-click="show_model"
            phx-value-id={model.id}
          >
            <div class="flex items-start gap-3">
              <div class="pt-0.5">
                <input
                  id={"compare-mobile-#{model.id}"}
                  type="checkbox"
                  checked={MapSet.member?(@selected_ids, model.id)}
                  disabled={!MapSet.member?(@selected_ids, model.id) && !@can_add_more}
                  phx-click="toggle_select"
                  phx-value-id={model.id}
                  class="rounded"
                  style="border-color: hsl(var(--border));"
                  aria-label={"Select #{model.name} for comparison"}
                />
              </div>
              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-2 flex-wrap">
                  <.link
                    patch={model_detail_path(model)}
                    class="font-medium truncate hover:underline"
                  >
                    {model.name}
                  </.link>
                  <%= if model.deprecated || lifecycle_status(model) != "active" do %>
                    <span
                      class="text-[10px] px-1 py-0 rounded"
                      style="background-color: hsl(var(--destructive) / 0.1); color: hsl(var(--destructive));"
                    >
                      {lifecycle_label(model)}
                    </span>
                  <% end %>
                </div>
                <div class="text-xs mt-0.5" style="color: hsl(var(--muted-foreground));">
                  {model.provider}
                </div>

                <div
                  :if={model.__last_changed_at}
                  class="text-xs mt-1"
                  style="color: hsl(var(--muted-foreground));"
                >
                  Updated {String.slice(model.__last_changed_at, 0, 10)}
                </div>

                <div
                  class="flex items-center gap-3 mt-2 text-xs"
                  style="color: hsl(var(--muted-foreground));"
                >
                  <.modality_badges model={model} />
                  <span class="font-mono">
                    {ModelLive.format_number(model_limit(model, :context))}
                  </span>
                  <span class="font-mono">
                    {ModelLive.format_cost(model_cost(model, :input))}/{ModelLive.format_cost(
                      model_cost(model, :output)
                    )}
                  </span>
                </div>

                <div class="flex flex-wrap gap-1 mt-2">
                  <.capability_badge
                    :if={model_has_capability?(model, :reasoning)}
                    capability={:reasoning}
                    compact
                  />
                  <.capability_badge
                    :if={model_has_capability?(model, :tools)}
                    capability={:tools}
                    compact
                  />
                  <.capability_badge
                    :if={model_has_capability?(model, :batch)}
                    capability={:batch}
                    compact
                  />
                  <.capability_badge
                    :if={model_has_capability?(model, :code_execution)}
                    capability={:code_execution}
                    compact
                  />
                  <.capability_badge :if={has_vision?(model)} capability={:vision} compact />
                  <.capability_badge
                    :if={embeddings_enabled?(model.capabilities)}
                    capability={:embeddings}
                    compact
                  />
                </div>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  attr :field, :atom, required: true
  attr :label, :string, required: true
  attr :sort, :map, required: true
  attr :align, :string, default: "left"

  defp sortable_header(assigns) do
    is_active = assigns.sort.by == assigns.field

    assigns =
      assigns
      |> assign(:is_active, is_active)

    ~H"""
    <th
      aria-sort={sortable_header_aria_sort(@is_active, @sort.dir)}
      class={"px-3 py-3 font-medium #{if @align == "right", do: "text-right", else: "text-left"}"}
      style="color: hsl(var(--muted-foreground));"
    >
      <button
        type="button"
        phx-click="sort"
        phx-value-by={@field}
        class={"flex w-full items-center gap-1 transition-colors select-none hover:opacity-80 #{if @align == "right", do: "justify-end", else: ""}"}
      >
        <span>{@label}</span>
        <%= if @is_active do %>
          <%= if @sort.dir == :asc do %>
            <.icon name="hero-arrow-up" class="h-3.5 w-3.5" />
          <% else %>
            <.icon name="hero-arrow-down" class="h-3.5 w-3.5" />
          <% end %>
        <% else %>
          <.icon name="hero-arrows-up-down" class="h-3.5 w-3.5 opacity-30" />
        <% end %>
      </button>
    </th>
    """
  end

  defp sortable_header_aria_sort(false, _direction), do: "none"
  defp sortable_header_aria_sort(true, :asc), do: "ascending"
  defp sortable_header_aria_sort(true, :desc), do: "descending"

  attr :model, :map, required: true

  defp modality_badges(assigns) do
    modalities = assigns.model.modalities || %{}
    input_list = map_value(modalities, :input) || []
    output_list = map_value(modalities, :output) || []
    all_modalities = (input_list ++ output_list) |> Enum.uniq()

    assigns = assign(assigns, :modalities, all_modalities)

    ~H"""
    <div class="flex gap-0.5">
      <span
        :for={mod <- @modalities}
        title={mod_label(mod)}
        style="color: hsl(var(--muted-foreground));"
      >
        <.modality_icon modality={mod} />
        <span class="sr-only">{mod_label(mod)}</span>
      </span>
    </div>
    """
  end

  attr :modality, :atom, required: true

  defp modality_icon(assigns) do
    ~H"""
    <%= case @modality do %>
      <% :text -> %>
        <.icon name="hero-document-text" class="h-3 w-3" />
      <% :image -> %>
        <.icon name="hero-photo" class="h-3 w-3" />
      <% :audio -> %>
        <.icon name="hero-speaker-wave" class="h-3 w-3" />
      <% :video -> %>
        <.icon name="hero-video-camera" class="h-3 w-3" />
      <% _ -> %>
        <.icon name="hero-question-mark-circle" class="h-3 w-3" />
    <% end %>
    """
  end

  defp has_vision?(model) do
    modalities = model.modalities || %{}
    input_list = map_value(modalities, :input) || []
    :image in input_list
  end

  defp model_detail_path(model) do
    provider = URI.encode(to_string(model.provider))

    model_id =
      model.model_id
      |> String.split("/")
      |> Enum.map(&URI.encode/1)
      |> Enum.join("/")

    "/models/#{provider}/#{model_id}"
  end

  # =============================================================================
  # Task 2.5: Model Detail Modal Component
  # =============================================================================

  attr :model, :map, default: nil
  attr :history_events, :list, default: []
  attr :history_meta, :map, default: %{}
  attr :history_available, :boolean, default: false
  attr :history_api_url, :string, default: nil

  def model_detail_modal(assigns) do
    assigns =
      assigns
      |> assign(:specification_rows, specification_rows(assigns.model))
      |> assign(:reasoning_metadata_rows, reasoning_metadata_rows(assigns.model))
      |> assign(:advanced_capability_rows, advanced_capability_rows(assigns.model))
      |> assign(:pricing_component_rows, pricing_component_rows(assigns.model))

    ~H"""
    <div
      :if={@model}
      id="model-detail-modal"
      class="fixed inset-0 z-50 flex items-center justify-center"
    >
      <div
        class="fixed inset-0 bg-black/50 backdrop-blur-sm"
        phx-click="close_model"
        aria-hidden="true"
      />
      <.focus_wrap
        id="model-detail-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby="model-detail-title"
        tabindex="-1"
        phx-mounted={JS.focus_first(to: "#model-detail-dialog")}
        class="relative z-10 w-full max-w-3xl max-h-[85vh] overflow-y-auto rounded-lg border shadow-lg m-4"
        style="border-color: hsl(var(--border)); background-color: hsl(var(--background));"
        phx-click-away="close_model"
        phx-window-keydown="close_model"
        phx-key="escape"
      >
        <div class="p-6">
          <div class="flex items-center gap-2 mb-1">
            <span class="text-sm" style="color: hsl(var(--muted-foreground));">
              {@model.provider}
            </span>
            <span
              class="text-xs px-2 py-0.5 rounded"
              style={"background-color: hsl(var(#{lifecycle_bg_color(@model)})); color: hsl(var(#{lifecycle_text_color(@model)}));"}
            >
              {lifecycle_label(@model)}
            </span>
            <span
              :if={@model.family}
              class="text-xs px-2 py-0.5 rounded border"
              style="border-color: hsl(var(--border));"
            >
              {@model.family}
            </span>
          </div>

          <h2 id="model-detail-title" class="text-2xl font-semibold mb-2">{@model.name}</h2>

          <div class="mb-4">
            <div class="text-xs mb-1" style="color: hsl(var(--muted-foreground));">Model Spec</div>
            <div class="flex items-center gap-2">
              <code
                class="text-sm px-2 py-1 rounded font-mono"
                style="background-color: hsl(var(--muted));"
              >
                {@model.provider}:{@model.model_id}
              </code>
              <button
                type="button"
                onclick={"navigator.clipboard.writeText('#{@model.provider}:#{@model.model_id}'); this.querySelector('.spec-copy-icon').classList.add('hidden'); this.querySelector('.spec-check-icon').classList.remove('hidden'); setTimeout(() => { this.querySelector('.spec-copy-icon').classList.remove('hidden'); this.querySelector('.spec-check-icon').classList.add('hidden'); }, 2000);"}
                class="p-1 rounded hover:opacity-80"
                title="Copy model spec"
                aria-label="Copy model spec"
              >
                <.icon name="hero-clipboard" class="h-3 w-3 spec-copy-icon" />
                <.icon name="hero-check" class="h-3 w-3 spec-check-icon hidden" />
              </button>
            </div>
          </div>

          <%= if has_modalities?(@model) do %>
            <div class="mb-6">
              <h3 class="text-sm font-semibold mb-3">Modalities</h3>
              <div class="grid grid-cols-2 gap-4">
                <div
                  class="rounded-lg border p-3"
                  style="border-color: hsl(var(--border)); background-color: hsl(var(--muted) / 0.3);"
                >
                  <div class="text-xs mb-2" style="color: hsl(var(--muted-foreground));">Input</div>
                  <div class="flex flex-wrap gap-2">
                    <%= for mod <- model_modalities(@model, :input) do %>
                      <span
                        class="inline-flex items-center gap-1.5 px-2 py-1 rounded text-sm"
                        style="background-color: hsl(var(--primary) / 0.1); color: hsl(var(--primary));"
                      >
                        <.modality_icon modality={mod} />
                        {mod}
                      </span>
                    <% end %>
                  </div>
                </div>
                <div
                  class="rounded-lg border p-3"
                  style="border-color: hsl(var(--border)); background-color: hsl(var(--muted) / 0.3);"
                >
                  <div class="text-xs mb-2" style="color: hsl(var(--muted-foreground));">Output</div>
                  <div class="flex flex-wrap gap-2">
                    <%= for mod <- model_modalities(@model, :output) do %>
                      <span
                        class="inline-flex items-center gap-1.5 px-2 py-1 rounded text-sm"
                        style="background-color: hsl(var(--secondary)); color: hsl(var(--secondary-foreground));"
                      >
                        <.modality_icon modality={mod} />
                        {mod}
                      </span>
                    <% end %>
                  </div>
                </div>
              </div>
            </div>
          <% end %>

          <div
            :if={not hide_history_section?(@history_available, @history_events)}
            class="mb-6"
          >
            <h3 class="text-sm font-semibold mb-3">Capabilities</h3>
            <div class="flex flex-wrap gap-2">
              <.capability_badge :if={model_has_capability?(@model, :chat)} capability={:chat} />
              <.capability_badge
                :if={model_has_capability?(@model, :reasoning)}
                capability={:reasoning}
              />
              <.capability_badge
                :if={model_has_capability?(@model, :tools)}
                capability={:tools}
              />
              <.capability_badge
                :if={model_has_capability?(@model, :batch)}
                capability={:batch}
              />
              <.capability_badge
                :if={model_has_capability?(@model, :citations)}
                capability={:citations}
              />
              <.capability_badge
                :if={model_has_capability?(@model, :code_execution)}
                capability={:code_execution}
              />
              <.capability_badge
                :if={model_has_capability?(@model, :context_management)}
                capability={:context_management}
              />
              <.capability_badge :if={has_vision?(@model)} capability={:vision} />
              <.capability_badge
                :if={model_has_capability?(@model, :streaming)}
                capability={:streaming}
              />
              <.capability_badge
                :if={embeddings_enabled?(@model.capabilities)}
                capability={:embeddings}
              />
              <.capability_badge
                :if={model_has_capability?(@model, :json_output)}
                capability={:json_output}
              />
            </div>
          </div>

          <div :if={@reasoning_metadata_rows != []} class="mb-6">
            <h3 class="text-sm font-semibold mb-3">Reasoning Metadata</h3>
            <div class="grid gap-3 md:grid-cols-3">
              <%= for row <- @reasoning_metadata_rows do %>
                <div
                  class="rounded-lg border p-3"
                  style="border-color: hsl(var(--border)); background-color: hsl(var(--muted) / 0.3);"
                >
                  <div class="text-xs mb-1" style="color: hsl(var(--muted-foreground));">
                    {row.label}
                  </div>
                  <div class="text-sm font-medium leading-snug">{row.value}</div>
                  <div
                    :if={row.detail}
                    class="mt-1 text-xs"
                    style="color: hsl(var(--muted-foreground));"
                  >
                    {row.detail}
                  </div>
                </div>
              <% end %>
            </div>
          </div>

          <div :if={@advanced_capability_rows != []} class="mb-6">
            <h3 class="text-sm font-semibold mb-3">Advanced Capabilities</h3>
            <div
              class="rounded-lg border divide-y overflow-hidden"
              style="border-color: hsl(var(--border));"
            >
              <%= for row <- @advanced_capability_rows do %>
                <div
                  class="grid grid-cols-[9rem_1fr] gap-3 px-3 py-2 text-sm"
                  style="border-color: hsl(var(--border));"
                >
                  <div class="font-medium">{row.label}</div>
                  <div style="color: hsl(var(--muted-foreground));">{row.value}</div>
                </div>
              <% end %>
            </div>
          </div>

          <div :if={@pricing_component_rows != []} class="mb-6">
            <h3 class="text-sm font-semibold mb-3">Pricing Components</h3>
            <div
              class="rounded-lg border overflow-x-auto"
              style="border-color: hsl(var(--border));"
            >
              <table class="w-full min-w-[640px] text-sm">
                <thead style="background-color: hsl(var(--table-header));">
                  <tr class="border-b" style="border-color: hsl(var(--table-border));">
                    <th class="px-3 py-2 text-left font-medium">Component</th>
                    <th class="px-3 py-2 text-left font-medium">Price</th>
                    <th class="px-3 py-2 text-left font-medium">Conditions</th>
                    <th class="px-3 py-2 text-left font-medium">Source</th>
                  </tr>
                </thead>
                <tbody>
                  <tr
                    :for={row <- @pricing_component_rows}
                    class="border-b last:border-b-0"
                    style="border-color: hsl(var(--table-border));"
                  >
                    <td class="px-3 py-2 font-mono text-xs">{row.id}</td>
                    <td class="px-3 py-2 font-mono text-xs">{row.price}</td>
                    <td class="px-3 py-2 text-xs">{row.conditions}</td>
                    <td class="px-3 py-2 text-xs" style="color: hsl(var(--muted-foreground));">
                      {row.source}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <div class="mb-6">
            <h3 class="text-sm font-semibold mb-3">Specifications</h3>
            <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
              <%= for row <- @specification_rows do %>
                <div
                  class="rounded-lg border p-3"
                  style="border-color: hsl(var(--border)); background-color: hsl(var(--muted) / 0.3);"
                >
                  <div class="text-xs mb-1" style="color: hsl(var(--muted-foreground));">
                    {row.label}
                  </div>
                  <div class="font-mono font-medium text-sm">{row.value}</div>
                </div>
              <% end %>
            </div>
          </div>

          <div class="mb-6">
            <div class="flex items-center justify-between mb-3">
              <h3 class="text-sm font-semibold">History</h3>
              <a
                :if={@history_api_url}
                href={@history_api_url}
                target="_blank"
                rel="noopener noreferrer"
                class="text-xs px-2 py-1 rounded border transition-colors hover:opacity-80"
                style="border-color: hsl(var(--border)); color: hsl(var(--muted-foreground));"
              >
                Raw JSON
              </a>
            </div>
            <p class="mb-3 text-xs" style="color: hsl(var(--muted-foreground));">
              Timeline is based on collected llm_db history snapshots and may be incomplete.
            </p>

            <%= if @history_available do %>
              <%= if @history_events == [] do %>
                <div
                  class="rounded-lg border p-3 text-sm"
                  style="border-color: hsl(var(--border)); background-color: hsl(var(--muted) / 0.3); color: hsl(var(--muted-foreground));"
                >
                  No history events available yet.
                </div>
              <% else %>
                <div class="max-h-[46vh] overflow-y-auto overscroll-contain space-y-2 pr-1">
                  <%= for event <- Enum.reverse(@history_events) do %>
                    <div
                      class="rounded-lg border p-3"
                      style="border-color: hsl(var(--border)); background-color: hsl(var(--muted) / 0.3);"
                    >
                      <div class="flex items-center justify-between gap-3 mb-2">
                        <span class="text-xs font-mono" style="color: hsl(var(--muted-foreground));">
                          {history_event_date(event)}
                        </span>
                        <span
                          class="text-[10px] px-2 py-0.5 rounded border"
                          style={history_event_type_style(event)}
                        >
                          {history_event_type(event)}
                        </span>
                      </div>
                      <div class="space-y-2">
                        <%= case history_change_rows(event, 3) do %>
                          <% [] -> %>
                            <span
                              :if={history_event_type(event) != "introduced"}
                              class="text-xs"
                              style="color: hsl(var(--muted-foreground));"
                            >
                              No field-level changes recorded
                            </span>
                          <% rows -> %>
                            <ul class="space-y-1.5">
                              <%= for row <- rows do %>
                                <li class="text-xs leading-relaxed">
                                  <span class="font-mono text-[11px] break-all">{row.path}</span>
                                  <span
                                    class="ml-1 text-[10px]"
                                    style="color: hsl(var(--muted-foreground));"
                                  >
                                    ({String.downcase(row.op)})
                                  </span>
                                  <div
                                    class="mt-0.5 break-words"
                                    style="color: hsl(var(--muted-foreground));"
                                  >
                                    <span class="text-[11px]">{row.before}</span>
                                    <span class="mx-1">→</span>
                                    <span class="text-[11px]" style="color: hsl(var(--foreground));">
                                      {row.after}
                                    </span>
                                  </div>
                                </li>
                              <% end %>
                            </ul>
                            <span
                              :if={history_change_overflow(event, 3) > 0}
                              class="text-[11px]"
                              style="color: hsl(var(--muted-foreground));"
                            >
                              +{history_change_overflow(event, 3)} more
                            </span>
                        <% end %>
                      </div>
                    </div>
                  <% end %>
                </div>
              <% end %>
            <% else %>
              <div
                class="rounded-lg border p-3 text-sm"
                style="border-color: hsl(var(--border)); background-color: hsl(var(--muted) / 0.3); color: hsl(var(--muted-foreground));"
              >
                History not available for this deployment.
              </div>
            <% end %>

            <div
              :if={map_size(@history_meta) > 0}
              class="mt-2 text-[11px]"
              style="color: hsl(var(--muted-foreground));"
            >
              {history_meta_summary(@history_meta)}
            </div>
          </div>

          <button
            type="button"
            phx-click="close_model"
            class="absolute top-4 right-4 p-2 rounded-md hover:opacity-80"
            style="color: hsl(var(--muted-foreground));"
            aria-label="Close model details"
            autofocus
          >
            <.icon name="hero-x-mark" class="h-5 w-5" />
          </button>
        </div>
      </.focus_wrap>
    </div>
    """
  end

  # =============================================================================
  # Task 2.6: Comparison Modal Component
  # =============================================================================

  attr :is_open, :boolean, required: true
  attr :models, :list, required: true
  attr :on_remove, :string, default: "remove_from_comparison"
  attr :on_clear, :string, default: "clear_comparison"
  attr :on_close, :string, default: "close_comparison"

  def comparison_modal(assigns) do
    capabilities = [
      :chat,
      :tools,
      :batch,
      :citations,
      :code_execution,
      :context_management,
      :streaming,
      :vision,
      :reasoning,
      :embeddings,
      :json_output
    ]

    assigns = assign(assigns, :capabilities, capabilities)

    ~H"""
    <div
      :if={@is_open}
      id="comparison-modal"
      class="fixed inset-0 z-50 flex items-center justify-center"
      phx-remove={JS.pop_focus()}
    >
      <div
        class="fixed inset-0 bg-black/50 backdrop-blur-sm"
        phx-click={@on_close}
        aria-hidden="true"
      />
      <.focus_wrap
        id="comparison-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby="comparison-title"
        tabindex="-1"
        phx-mounted={JS.focus_first(to: "#comparison-dialog")}
        class="relative z-10 w-full max-w-5xl max-h-[85vh] overflow-y-auto rounded-lg border shadow-lg m-4"
        style="border-color: hsl(var(--border)); background-color: hsl(var(--background));"
        phx-click-away={@on_close}
        phx-window-keydown={@on_close}
        phx-key="escape"
      >
        <div class="p-6">
          <div class="flex items-center justify-between mb-4">
            <h2 id="comparison-title" class="text-xl font-semibold">
              Compare Models ({length(@models)})
            </h2>
            <div class="flex gap-2">
              <button
                type="button"
                onclick="navigator.clipboard.writeText(window.location.href); this.textContent = 'Copied!'; setTimeout(() => this.textContent = 'Share', 2000);"
                class="px-3 py-1.5 text-sm rounded-md border flex items-center gap-1"
                style="border-color: hsl(var(--border));"
              >
                <.icon name="hero-clipboard" class="h-4 w-4" /> Share
              </button>
              <button type="button" phx-click={@on_clear} class="px-3 py-1.5 text-sm hover:opacity-80">
                Clear all
              </button>
            </div>
          </div>

          <%= if length(@models) == 0 do %>
            <div class="py-12 text-center" style="color: hsl(var(--muted-foreground));">
              Select models from the table to compare
            </div>
          <% else %>
            <div class="space-y-6">
              <div
                class="grid gap-4"
                style={"grid-template-columns: repeat(#{length(@models)}, 1fr);"}
              >
                <%= for model <- @models do %>
                  <div
                    class="relative rounded-lg border p-3"
                    style="border-color: hsl(var(--border)); background-color: hsl(var(--card));"
                  >
                    <button
                      type="button"
                      phx-click={@on_remove}
                      phx-value-id={model.id}
                      class="absolute top-1 right-1 h-6 w-6 flex items-center justify-center rounded hover:opacity-80"
                      aria-label={"Remove #{model.name} from comparison"}
                    >
                      <.icon name="hero-x-mark" class="h-3 w-3" />
                    </button>
                    <div class="flex items-center gap-2">
                      <span class="text-xs" style="color: hsl(var(--muted-foreground));">
                        {model.provider}
                      </span>
                      <span
                        class="text-[10px] px-1 py-0 rounded"
                        style={"background-color: hsl(var(#{lifecycle_bg_color(model)})); color: hsl(var(#{lifecycle_text_color(model)}));"}
                      >
                        {lifecycle_label(model)}
                      </span>
                    </div>
                    <div class="font-medium">{model.name}</div>
                    <div class="text-xs font-mono mt-1" style="color: hsl(var(--muted-foreground));">
                      {model.model_id}
                    </div>
                    <div
                      :if={model.family}
                      class="text-xs mt-1"
                      style="color: hsl(var(--muted-foreground));"
                    >
                      Family: {model.family}
                    </div>
                  </div>
                <% end %>
              </div>

              <div class="space-y-3">
                <h4 class="text-sm font-medium" style="color: hsl(var(--muted-foreground));">
                  Modalities
                </h4>
                <div
                  class="rounded-lg border overflow-hidden"
                  style="border-color: hsl(var(--border));"
                >
                  <div
                    class="grid border-b"
                    style={"grid-template-columns: 120px repeat(#{length(@models)}, 1fr); border-color: hsl(var(--border)); background-color: hsl(var(--muted) / 0.5);"}
                  >
                    <div class="p-2 text-xs font-medium">Input</div>
                    <%= for model <- @models do %>
                      <div class="p-2 flex gap-1 justify-center flex-wrap">
                        <%= for mod <- model_modalities(model, :input) do %>
                          <span
                            class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[10px]"
                            style="background-color: hsl(var(--primary) / 0.1); color: hsl(var(--primary));"
                          >
                            <.modality_icon modality={mod} />
                            {mod}
                          </span>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                  <div
                    class="grid"
                    style={"grid-template-columns: 120px repeat(#{length(@models)}, 1fr);"}
                  >
                    <div class="p-2 text-xs font-medium">Output</div>
                    <%= for model <- @models do %>
                      <div class="p-2 flex gap-1 justify-center flex-wrap">
                        <%= for mod <- model_modalities(model, :output) do %>
                          <span
                            class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[10px]"
                            style="background-color: hsl(var(--secondary)); color: hsl(var(--secondary-foreground));"
                          >
                            <.modality_icon modality={mod} />
                            {mod}
                          </span>
                        <% end %>
                      </div>
                    <% end %>
                  </div>
                </div>
              </div>

              <div class="space-y-3">
                <h4 class="text-sm font-medium" style="color: hsl(var(--muted-foreground));">
                  Specifications
                </h4>
                <div
                  class="rounded-lg border overflow-hidden"
                  style="border-color: hsl(var(--border));"
                >
                  <.comparison_spec_row
                    label="Context"
                    models={@models}
                    getter={fn m -> ModelLive.format_number(model_limit(m, :context)) end}
                    bg
                  />
                  <.comparison_spec_row
                    :if={Enum.any?(@models, &(model_limit(&1, :input) != nil))}
                    label="Max Input"
                    models={@models}
                    getter={fn m -> ModelLive.format_number(model_limit(m, :input)) end}
                  />
                  <.comparison_spec_row
                    label="Max Output"
                    models={@models}
                    getter={fn m -> ModelLive.format_number(model_limit(m, :output)) end}
                  />
                  <.comparison_spec_row
                    label="Input Cost"
                    models={@models}
                    getter={fn m -> "#{ModelLive.format_cost(model_cost(m, :input))}/M" end}
                    bg
                  />
                  <.comparison_spec_row
                    label="Output Cost"
                    models={@models}
                    getter={fn m -> "#{ModelLive.format_cost(model_cost(m, :output))}/M" end}
                  />
                </div>
              </div>

              <div class="space-y-3">
                <h4 class="text-sm font-medium" style="color: hsl(var(--muted-foreground));">
                  Capabilities
                </h4>
                <div
                  class="rounded-lg border overflow-hidden"
                  style="border-color: hsl(var(--border));"
                >
                  <%= for {cap, idx} <- Enum.with_index(@capabilities) do %>
                    <.comparison_capability_row
                      capability={cap}
                      models={@models}
                      bg={rem(idx, 2) == 0}
                      last={idx == length(@capabilities) - 1}
                    />
                  <% end %>
                </div>
              </div>
            </div>
          <% end %>

          <button
            type="button"
            phx-click={@on_close}
            class="absolute top-4 right-4 p-2 rounded-md hover:opacity-80"
            style="color: hsl(var(--muted-foreground));"
            aria-label="Close comparison"
            autofocus
          >
            <.icon name="hero-x-mark" class="h-5 w-5" />
          </button>
        </div>
      </.focus_wrap>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :models, :list, required: true
  attr :getter, :any, required: true
  attr :bg, :boolean, default: false

  defp comparison_spec_row(assigns) do
    ~H"""
    <div
      class="grid border-b last:border-b-0"
      style={"grid-template-columns: 120px repeat(#{length(@models)}, 1fr); border-color: hsl(var(--border)); #{if @bg, do: "background-color: hsl(var(--muted) / 0.5);", else: ""}"}
    >
      <div class="p-2 text-xs font-medium">{@label}</div>
      <%= for model <- @models do %>
        <div class="p-2 text-xs font-mono text-center">{@getter.(model)}</div>
      <% end %>
    </div>
    """
  end

  attr :capability, :atom, required: true
  attr :models, :list, required: true
  attr :bg, :boolean, default: false
  attr :last, :boolean, default: false

  defp comparison_capability_row(assigns) do
    label = Map.get(@capability_labels, assigns.capability, to_string(assigns.capability))
    assigns = assign(assigns, :label, label)

    ~H"""
    <div
      class={"grid #{if @last, do: "", else: "border-b"}"}
      style={"grid-template-columns: 120px repeat(#{length(@models)}, 1fr); border-color: hsl(var(--border)); #{if @bg, do: "background-color: hsl(var(--muted) / 0.5);", else: ""}"}
    >
      <div class="p-2 text-xs font-medium">{@label}</div>
      <%= for model <- @models do %>
        <div class="p-2 text-center">
          <%= if model_has_capability?(model, @capability) do %>
            <.capability_badge capability={@capability} compact />
          <% else %>
            <span class="text-xs" style="color: hsl(var(--muted-foreground));">—</span>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp model_has_capability?(model, :chat), do: capability_enabled?(model.capabilities, [:chat])

  defp model_has_capability?(model, :tools),
    do: capability_enabled?(model.capabilities, [:tools, :enabled])

  defp model_has_capability?(model, :batch),
    do: capability_enabled?(model.capabilities, [:batch, :supported])

  defp model_has_capability?(model, :citations),
    do: capability_enabled?(model.capabilities, [:citations, :supported])

  defp model_has_capability?(model, :code_execution),
    do: capability_enabled?(model.capabilities, [:code_execution, :supported])

  defp model_has_capability?(model, :context_management),
    do: capability_enabled?(model.capabilities, [:context_management, :supported])

  defp model_has_capability?(model, :streaming),
    do: capability_enabled?(model.capabilities, [:streaming, :text])

  defp model_has_capability?(model, :vision), do: has_vision?(model)

  defp model_has_capability?(model, :reasoning),
    do: capability_enabled?(model.capabilities, [:reasoning, :enabled])

  defp model_has_capability?(model, :embeddings), do: embeddings_enabled?(model.capabilities)

  defp model_has_capability?(model, :json_output) do
    capability_enabled?(model.capabilities, [:json, :native]) ||
      capability_enabled?(model.capabilities, [:json, :schema])
  end

  defp model_has_capability?(_, _), do: false

  defp specification_rows(nil), do: []

  defp specification_rows(model) do
    rows = [
      %{label: "Context Window", value: format_token_metric(model_limit(model, :context))},
      %{label: "Max Output", value: format_token_metric(model_limit(model, :output))},
      %{label: "Input Cost", value: "#{ModelLive.format_cost(model_cost(model, :input))}/M"},
      %{label: "Output Cost", value: "#{ModelLive.format_cost(model_cost(model, :output))}/M"}
    ]

    case model_limit(model, :input) do
      nil -> rows
      input -> List.insert_at(rows, 1, %{label: "Max Input", value: format_token_metric(input)})
    end
  end

  defp reasoning_metadata_rows(nil), do: []

  defp reasoning_metadata_rows(model) do
    reasoning = nested_get(model, [:capabilities, :reasoning])

    [
      reasoning_effort_row(reasoning),
      reasoning_thinking_row(reasoning),
      reasoning_token_budget_row(reasoning)
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp reasoning_effort_row(%{} = reasoning) do
    effort = map_value(reasoning, :effort)

    if is_map(effort) do
      values = effort |> map_value(:values) |> list_values()
      default = map_value(effort, :default)
      supported? = capability_truthy?(map_value(effort, :supported))

      cond do
        values != [] ->
          %{
            label: "Effort",
            value: Enum.join(values, ", "),
            detail: detail_value("Default", default)
          }

        supported? ->
          %{label: "Effort", value: "Supported", detail: detail_value("Default", default)}

        true ->
          nil
      end
    end
  end

  defp reasoning_effort_row(_reasoning), do: nil

  defp reasoning_thinking_row(%{} = reasoning) do
    thinking = map_value(reasoning, :thinking)

    if is_map(thinking) do
      types = thinking |> map_value(:types) |> list_values()
      default_type = map_value(thinking, :default_type)

      flags =
        [
          {:raw_output_supported, "Raw output"},
          {:summary_supported, "Summary"},
          {:encrypted_supported, "Encrypted"},
          {:disable_supported, "Disable"}
        ]
        |> Enum.filter(fn {key, _label} -> capability_truthy?(map_value(thinking, key)) end)
        |> Enum.map(fn {_key, label} -> label end)

      cond do
        types != [] ->
          %{
            label: "Thinking",
            value: Enum.join(types, ", "),
            detail:
              [detail_value("Default", default_type), join_or_nil(flags)] |> compact_join(" • ")
          }

        flags != [] ->
          %{
            label: "Thinking",
            value: Enum.join(flags, ", "),
            detail: detail_value("Default", default_type)
          }

        true ->
          nil
      end
    end
  end

  defp reasoning_thinking_row(_reasoning), do: nil

  defp reasoning_token_budget_row(%{} = reasoning) do
    case map_value(reasoning, :token_budget) do
      budget when is_integer(budget) ->
        %{label: "Token Budget", value: ModelLive.format_number(budget), detail: nil}

      %{} = budget ->
        parts =
          [
            budget_part("Min", map_value(budget, :min)),
            budget_part("Max", map_value(budget, :max)),
            budget_part("Default", map_value(budget, :default))
          ]
          |> Enum.reject(&is_nil/1)

        if parts == [] do
          nil
        else
          %{label: "Token Budget", value: Enum.join(parts, ", "), detail: nil}
        end

      _ ->
        nil
    end
  end

  defp reasoning_token_budget_row(_reasoning), do: nil

  defp advanced_capability_rows(nil), do: []

  defp advanced_capability_rows(model) do
    [
      advanced_capability_row(model, :batch, "Batch"),
      advanced_capability_row(model, :citations, "Citations"),
      advanced_capability_row(model, :code_execution, "Code Execution"),
      advanced_capability_row(model, :context_management, "Context Management")
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp advanced_capability_row(model, key, label) do
    capability = nested_get(model, [:capabilities, key])

    if capability_enabled?(model.capabilities, [key, :supported]) ||
         capability_enabled?(model.capabilities, [key, :enabled]) ||
         capability_truthy?(capability) do
      %{
        label: label,
        value: capability_summary(capability)
      }
    end
  end

  defp pricing_component_rows(nil), do: []

  defp pricing_component_rows(model) do
    model
    |> nested_get([:pricing, :components])
    |> case do
      components when is_list(components) ->
        components
        |> Enum.filter(&is_map/1)
        |> Enum.map(&pricing_component_row/1)

      _ ->
        []
    end
  end

  defp pricing_component_row(component) do
    %{
      id: component |> map_value(:id) |> value_or_dash(),
      price: format_component_price(component),
      conditions: format_component_conditions(component),
      source:
        [map_value(component, :source), map_value(component, :mode), map_value(component, :meter)]
        |> Enum.reject(&blank?/1)
        |> Enum.map(&to_string/1)
        |> compact_join(" • ")
        |> value_or_dash()
    }
  end

  defp model_modalities(model, direction) do
    case nested_get(model, [:modalities, direction]) do
      values when is_list(values) -> values
      _ -> []
    end
  end

  defp model_limit(model, key), do: nested_get(model, [:limits, key])
  defp model_cost(model, key), do: nested_get(model, [:cost, key])

  defp nested_get(value, []), do: value

  defp nested_get(value, [key | rest]) when is_map(value) do
    case map_value(value, key) do
      nil -> nil
      nested -> nested_get(nested, rest)
    end
  end

  defp nested_get(_value, _path), do: nil

  defp map_value(map, key) when is_map(map) and is_atom(key) do
    string_key = Atom.to_string(key)

    cond do
      Map.has_key?(map, key) -> Map.get(map, key)
      Map.has_key?(map, string_key) -> Map.get(map, string_key)
      true -> nil
    end
  end

  defp map_value(map, key) when is_map(map) and is_binary(key) do
    if Map.has_key?(map, key), do: Map.get(map, key)
  end

  defp map_value(_map, _key), do: nil

  defp capability_enabled?(caps, path) do
    value = nested_get(caps || %{}, path)

    cond do
      is_nil(value) and length(path) > 1 ->
        [root | _rest] = path
        fallback_capability_enabled?(map_value(caps || %{}, root))

      true ->
        capability_truthy?(value)
    end
  end

  defp fallback_capability_enabled?(%{} = capability) do
    cond do
      not is_nil(map_value(capability, :enabled)) ->
        capability_truthy?(map_value(capability, :enabled))

      not is_nil(map_value(capability, :supported)) ->
        capability_truthy?(map_value(capability, :supported))

      true ->
        capability_truthy?(capability)
    end
  end

  defp fallback_capability_enabled?(value), do: capability_truthy?(value)

  defp capability_truthy?(nil), do: false
  defp capability_truthy?(false), do: false
  defp capability_truthy?(true), do: true

  defp capability_truthy?(%{} = capability) do
    cond do
      not is_nil(map_value(capability, :enabled)) ->
        capability_truthy?(map_value(capability, :enabled))

      not is_nil(map_value(capability, :supported)) ->
        capability_truthy?(map_value(capability, :supported))

      true ->
        map_size(capability) > 0
    end
  end

  defp capability_truthy?(value), do: value not in [nil, false]

  defp format_token_metric(nil), do: "N/A tokens"
  defp format_token_metric(value), do: "#{ModelLive.format_number(value)} tokens"

  defp format_component_price(component) do
    rate = map_value(component, :rate)
    multiplier = map_value(component, :multiplier)

    cond do
      is_number(rate) ->
        "#{ModelLive.format_cost(rate)} / #{format_component_unit(component)}"

      is_number(multiplier) ->
        "#{:erlang.float_to_binary(multiplier * 1.0, decimals: 2)}x"

      true ->
        "—"
    end
  end

  defp format_component_unit(component) do
    per = map_value(component, :per)
    unit = component |> map_value(:unit) |> value_or("unit")

    case per do
      1_000_000 -> "1M #{unit}s"
      value when is_integer(value) -> "#{ModelLive.format_number(value)} #{unit}s"
      _ -> unit
    end
  end

  defp format_component_conditions(component) do
    applies_when = map_value(component, :applies_when)
    excludes_when = map_value(component, :excludes_when)

    [
      condition_part(nil, applies_when),
      condition_part("excludes", excludes_when)
    ]
    |> Enum.reject(&blank?/1)
    |> compact_join(" • ")
    |> value_or("Standard")
  end

  defp condition_part(_prefix, nil), do: nil
  defp condition_part(_prefix, %{} = map) when map_size(map) == 0, do: nil

  defp condition_part(prefix, value) do
    formatted = format_condition_value(value)

    if prefix do
      "#{prefix}: #{formatted}"
    else
      formatted
    end
  end

  defp format_condition_value(%{} = map) do
    map
    |> Enum.sort_by(fn {key, _value} -> to_string(key) end)
    |> Enum.map(fn {key, value} ->
      "#{format_condition_key(key)}: #{format_condition_value(value)}"
    end)
    |> Enum.join(", ")
  end

  defp format_condition_value(values) when is_list(values) do
    values
    |> list_values()
    |> Enum.join(", ")
  end

  defp format_condition_value(value) when is_integer(value), do: ModelLive.format_number(value)
  defp format_condition_value(value), do: value |> to_string() |> String.replace("_", " ")

  defp format_condition_key(key), do: key |> to_string() |> String.replace("_", " ")

  defp capability_summary(true), do: "Supported"

  defp capability_summary(%{} = capability) do
    features =
      [map_value(capability, :features), map_value(capability, :types)]
      |> Enum.flat_map(&list_values/1)

    cond do
      features != [] -> Enum.join(features, ", ")
      capability_truthy?(capability) -> "Supported"
      true -> "—"
    end
  end

  defp capability_summary(_capability), do: "Supported"

  defp budget_part(_label, nil), do: nil
  defp budget_part(label, value), do: "#{label} #{ModelLive.format_number(value)}"

  defp detail_value(_label, nil), do: nil
  defp detail_value(label, value), do: "#{label}: #{value}"

  defp join_or_nil([]), do: nil
  defp join_or_nil(values), do: Enum.join(values, ", ")

  defp compact_join(values, joiner) do
    values
    |> Enum.reject(&blank?/1)
    |> Enum.join(joiner)
  end

  defp list_values(nil), do: []

  defp list_values(values) when is_list(values) do
    Enum.map(values, &format_list_value/1)
  end

  defp list_values(value), do: [format_list_value(value)]

  defp format_list_value(value) do
    value
    |> to_string()
    |> String.replace("_", " ")
  end

  defp value_or(nil, fallback), do: fallback
  defp value_or("", fallback), do: fallback
  defp value_or(value, _fallback), do: value

  defp value_or_dash(value), do: value_or(value, "—")

  defp blank?(nil), do: true
  defp blank?(""), do: true
  defp blank?(_value), do: false

  defp history_event_date(event) do
    event
    |> map_get("captured_at", :captured_at, "unknown")
    |> to_string()
    |> String.slice(0, 10)
  end

  defp history_event_type(event) do
    event
    |> map_get("type", :type, "changed")
    |> to_string()
  end

  defp hide_history_section?(true, [event]) do
    history_event_type(event) == "introduced"
  end

  defp hide_history_section?(_available, _events), do: false

  defp history_event_type_style(event) do
    case history_event_type(event) do
      "introduced" ->
        "border-color: hsl(var(--cap-chat) / 0.4); color: hsl(var(--cap-chat)); background-color: hsl(var(--cap-chat) / 0.15);"

      "removed" ->
        "border-color: hsl(var(--cap-reason) / 0.4); color: hsl(var(--cap-reason)); background-color: hsl(var(--cap-reason) / 0.15);"

      _ ->
        "border-color: hsl(var(--cap-stream) / 0.4); color: hsl(var(--cap-stream)); background-color: hsl(var(--cap-stream) / 0.15);"
    end
  end

  defp history_change_rows(event, max_items) do
    event
    |> map_get("changes", :changes, [])
    |> Enum.map(&history_change_row/1)
    |> Enum.filter(fn row -> row.path != "" end)
    |> Enum.take(max_items)
  end

  defp history_change_overflow(event, max_items) do
    total_changes =
      event
      |> map_get("changes", :changes, [])
      |> length()

    max(total_changes - max_items, 0)
  end

  defp history_change_row(change) do
    %{
      path:
        change
        |> map_get("path", :path, "")
        |> to_string(),
      op:
        change
        |> map_get("op", :op, "replace")
        |> to_string(),
      before:
        change
        |> map_get("before", :before, nil)
        |> history_format_value(),
      after:
        change
        |> map_get("after", :after, nil)
        |> history_format_value()
    }
  end

  defp history_format_value(nil), do: "—"

  defp history_format_value(value) when is_binary(value) do
    value
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
    |> truncate_history_value(80)
  end

  defp history_format_value(value) when is_boolean(value) or is_number(value) do
    to_string(value)
  end

  defp history_format_value(value) when is_list(value) do
    "[#{length(value)} items]"
  end

  defp history_format_value(value) when is_map(value) do
    "{#{map_size(value)} fields}"
  end

  defp history_format_value(value) do
    value
    |> inspect()
    |> truncate_history_value(80)
  end

  defp truncate_history_value(value, max_len) when is_binary(value) and is_integer(max_len) do
    if String.length(value) > max_len do
      String.slice(value, 0, max_len - 3) <> "..."
    else
      value
    end
  end

  defp history_meta_summary(meta) do
    range_kind =
      map_get(meta, "range_kind", :range_kind) ||
        if(
          is_binary(map_get(meta, "from_snapshot_id", :from_snapshot_id)) and
            is_binary(map_get(meta, "to_snapshot_id", :to_snapshot_id)),
          do: "snapshots",
          else: "commits"
        )

    from_ref =
      map_get(meta, "from_ref", :from_ref) ||
        map_get(meta, "from_snapshot_id", :from_snapshot_id) ||
        map_get(meta, "from_commit", :from_commit)

    to_ref =
      map_get(meta, "to_ref", :to_ref) ||
        map_get(meta, "to_snapshot_id", :to_snapshot_id) ||
        map_get(meta, "to_commit", :to_commit)

    generated_at = map_get(meta, "generated_at", :generated_at)

    range_summary =
      cond do
        is_binary(from_ref) and is_binary(to_ref) ->
          "#{range_kind} #{short_sha(from_ref)} -> #{short_sha(to_ref)}"

        true ->
          nil
      end

    generated_summary =
      if is_binary(generated_at) do
        "generated #{String.slice(generated_at, 0, 19)}"
      end

    [range_summary, generated_summary]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" • ")
  end

  defp short_sha(sha) when is_binary(sha), do: String.slice(sha, 0, 7)

  defp map_get(map, string_key, atom_key, default \\ nil)

  defp map_get(map, string_key, atom_key, default) when is_map(map) do
    cond do
      Map.has_key?(map, string_key) -> Map.get(map, string_key)
      Map.has_key?(map, atom_key) -> Map.get(map, atom_key)
      true -> default
    end
  end

  defp map_get(_value, _string_key, _atom_key, default), do: default

  # =============================================================================
  # Legacy Components (kept for backwards compatibility)
  # =============================================================================

  attr :sort, :map, required: true
  attr :by, :atom, required: true
  slot :inner_block, required: true

  def sort_header(assigns) do
    ~H"""
    <span class="inline-flex items-center gap-1">
      {render_slot(@inner_block)}
      <%= if @sort.by == @by do %>
        {if @sort.dir == :asc, do: "↑", else: "↓"}
      <% end %>
    </span>
    """
  end

  attr :model, :map, required: true

  def capability_badges(assigns) do
    caps = assigns.model.capabilities || %{}

    badges =
      Catalog.labeled_capabilities()
      |> Enum.filter(fn {_key, path, _label, _tooltip} -> get_capability(caps, path) end)
      |> Enum.map(fn {_key, _path, label, tooltip} -> {label, tooltip} end)

    assigns = assign(assigns, :badges, badges)

    ~H"""
    <div class="flex flex-wrap gap-1.5">
      <%= for {label, tooltip} <- @badges do %>
        <span
          class="px-2 py-0.5 text-xs font-medium rounded border"
          title={tooltip}
          style="background-color: hsl(var(--muted)); color: hsl(var(--muted-foreground)); border-color: hsl(var(--border));"
        >
          {label}
        </span>
      <% end %>
    </div>
    """
  end

  defp get_capability(caps, path), do: capability_enabled?(caps, path)

  attr :label, :string, required: true
  slot :value, required: true

  def metric(assigns) do
    ~H"""
    <div>
      <div class="text-xs font-medium uppercase mb-1" style="color: hsl(var(--muted-foreground));">
        {@label}
      </div>
      <div class="text-sm" style="color: hsl(var(--foreground));">
        {render_slot(@value)}
      </div>
    </div>
    """
  end

  attr :model, :map, required: true

  def model_card(assigns) do
    ~H"""
    <.card>
      <.card_content>
        <div class="space-y-3">
          <div class="flex items-start justify-between gap-3">
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2 mb-1">
                <.badge color="primary" variant="light">{@model.provider}</.badge>
                <%= if @model.deprecated do %>
                  <.badge color="danger" size="xs">Deprecated</.badge>
                <% end %>
              </div>
              <h3 class="text-base font-semibold truncate" style="color: hsl(var(--foreground));">
                {@model.name}
              </h3>
              <p class="text-sm truncate" style="color: hsl(var(--muted-foreground));">
                {@model.model_id}
              </p>
              <%= if @model.family do %>
                <p class="text-xs mt-1" style="color: hsl(var(--muted-foreground));">
                  {@model.family}
                </p>
              <% end %>
            </div>
          </div>

          <%= if has_capabilities?(@model) do %>
            <div>
              <div
                class="text-xs font-medium uppercase mb-1"
                style="color: hsl(var(--muted-foreground));"
              >
                Capabilities
              </div>
              <.capability_badges model={@model} />
            </div>
          <% end %>

          <div class="grid grid-cols-2 gap-3 pt-3 border-t" style="border-color: hsl(var(--border));">
            <.metric label="Context">
              <:value>{ModelLive.format_number(model_limit(@model, :context))}</:value>
            </.metric>
            <.metric label="Output">
              <:value>{ModelLive.format_number(model_limit(@model, :output))}</:value>
            </.metric>
            <.metric label="Cost In">
              <:value>{ModelLive.format_cost(model_cost(@model, :input))}</:value>
            </.metric>
            <.metric label="Cost Out">
              <:value>{ModelLive.format_cost(model_cost(@model, :output))}</:value>
            </.metric>
          </div>
        </div>
      </.card_content>
    </.card>
    """
  end

  attr :providers, :list, required: true
  attr :filters, :map, required: true
  attr :filters_open, :boolean, required: true

  def filters_sidebar(assigns) do
    ~H"""
    <div class={"lg:col-span-1 #{if @filters_open, do: "block", else: "hidden lg:block"} fixed lg:static inset-0 lg:inset-auto z-40 lg:z-auto"}>
      <div class="lg:hidden fixed inset-0 bg-black/50 backdrop-blur-sm" phx-click="toggle_filters">
      </div>

      <div
        class="fixed lg:static inset-y-0 left-0 w-80 max-w-[85vw] lg:w-auto lg:max-w-none shadow-xl lg:shadow-none overflow-y-auto lg:overflow-visible"
        style="background-color: hsl(var(--background));"
      >
        <div class="lg:sticky lg:top-4 p-4 lg:p-0">
          <div class="flex items-center justify-between mb-4 lg:hidden">
            <h2 class="text-lg font-semibold">Filters</h2>
            <button
              type="button"
              phx-click="toggle_filters"
              class="p-2 hover:opacity-80"
              aria-label="Close filters"
            >
              <.icon name="hero-x-mark" class="w-6 h-6" />
            </button>
          </div>

          <.card variant="outline" class="border-0 lg:border shadow-none lg:shadow">
            <.card_content category="Filters">
              <form id="legacy-filters-form" phx-change="filter" phx-debounce="200">
                <div class="mb-6">
                  <.form_label>Providers</.form_label>
                  <.input
                    type="text"
                    name="provider_search"
                    value={@filters.provider_search}
                    placeholder="Search providers..."
                    class="mb-2"
                    phx-debounce="200"
                  />
                  <div class="space-y-2 max-h-48 overflow-y-auto">
                    <%= for provider <- filtered_providers(@providers, @filters.provider_search) do %>
                      <label class="flex items-center gap-2 cursor-pointer">
                        <input
                          type="checkbox"
                          name={"providers[#{provider.id}]"}
                          checked={MapSet.member?(@filters.provider_ids, to_string(provider.id))}
                          class="rounded"
                          style="border-color: hsl(var(--border));"
                        />
                        <span class="text-sm">
                          {provider.name}
                        </span>
                      </label>
                    <% end %>
                  </div>
                </div>

                <div class="mb-6 space-y-2">
                  <label class="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      name="show_deprecated"
                      value="true"
                      checked={@filters.show_deprecated}
                      class="rounded"
                      style="border-color: hsl(var(--border));"
                    />
                    <span class="text-sm">Show deprecated</span>
                  </label>

                  <label class="flex items-center gap-2 cursor-pointer">
                    <input
                      type="checkbox"
                      name="allowed_only"
                      value="true"
                      checked={@filters.allowed_only}
                      class="rounded"
                      style="border-color: hsl(var(--border));"
                    />
                    <span class="text-sm">Allowed only</span>
                  </label>
                </div>

                <div class="mb-6">
                  <.form_label>Capabilities</.form_label>
                  <div class="space-y-2">
                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        name="cap_chat"
                        value="true"
                        checked={@filters.capabilities.chat}
                        class="rounded"
                        style="border-color: hsl(var(--border));"
                      />
                      <span class="text-sm">Chat</span>
                    </label>

                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        name="cap_embeddings"
                        value="true"
                        checked={@filters.capabilities.embeddings}
                        class="rounded"
                        style="border-color: hsl(var(--border));"
                      />
                      <span class="text-sm">Embeddings</span>
                    </label>

                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        name="cap_reasoning"
                        value="true"
                        checked={@filters.capabilities.reasoning}
                        class="rounded"
                        style="border-color: hsl(var(--border));"
                      />
                      <span class="text-sm">Reasoning</span>
                    </label>

                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        name="cap_tools"
                        value="true"
                        checked={@filters.capabilities.tools}
                        class="rounded"
                        style="border-color: hsl(var(--border));"
                      />
                      <span class="text-sm">Tools</span>
                    </label>

                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        name="cap_json_native"
                        value="true"
                        checked={@filters.capabilities.json_native}
                        class="rounded"
                        style="border-color: hsl(var(--border));"
                      />
                      <span class="text-sm">JSON Native</span>
                    </label>

                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        name="cap_streaming_text"
                        value="true"
                        checked={@filters.capabilities.streaming_text}
                        class="rounded"
                        style="border-color: hsl(var(--border));"
                      />
                      <span class="text-sm">Streaming</span>
                    </label>

                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        name="cap_batch"
                        value="true"
                        checked={@filters.capabilities.batch}
                        class="rounded"
                        style="border-color: hsl(var(--border));"
                      />
                      <span class="text-sm">Batch</span>
                    </label>

                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        name="cap_citations"
                        value="true"
                        checked={@filters.capabilities.citations}
                        class="rounded"
                        style="border-color: hsl(var(--border));"
                      />
                      <span class="text-sm">Citations</span>
                    </label>

                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        name="cap_code_execution"
                        value="true"
                        checked={@filters.capabilities.code_execution}
                        class="rounded"
                        style="border-color: hsl(var(--border));"
                      />
                      <span class="text-sm">Code Execution</span>
                    </label>

                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        name="cap_context_management"
                        value="true"
                        checked={@filters.capabilities.context_management}
                        class="rounded"
                        style="border-color: hsl(var(--border));"
                      />
                      <span class="text-sm">Context Management</span>
                    </label>
                  </div>
                </div>

                <div class="mb-6">
                  <.form_label>Input Modalities</.form_label>
                  <div class="space-y-2">
                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        name="modalities_in[text]"
                        checked={MapSet.member?(@filters.modalities_in, :text)}
                        class="rounded"
                        style="border-color: hsl(var(--border));"
                      />
                      <span class="text-sm">Text</span>
                    </label>

                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        name="modalities_in[image]"
                        checked={MapSet.member?(@filters.modalities_in, :image)}
                        class="rounded"
                        style="border-color: hsl(var(--border));"
                      />
                      <span class="text-sm">Image</span>
                    </label>

                    <label class="flex items-center gap-2 cursor-pointer">
                      <input
                        type="checkbox"
                        name="modalities_in[audio]"
                        checked={MapSet.member?(@filters.modalities_in, :audio)}
                        class="rounded"
                        style="border-color: hsl(var(--border));"
                      />
                      <span class="text-sm">Audio</span>
                    </label>
                  </div>
                </div>

                <div class="mb-6">
                  <.form_label>Minimum Context</.form_label>
                  <.input
                    type="number"
                    name="min_context"
                    value={@filters.min_context}
                    placeholder="e.g., 32000"
                  />
                </div>

                <div class="mb-6">
                  <.form_label>Minimum Output</.form_label>
                  <.input
                    type="number"
                    name="min_output"
                    value={@filters.min_output}
                    placeholder="e.g., 4000"
                  />
                </div>

                <div class="mb-6">
                  <.form_label>Max Cost In ($/1M tokens)</.form_label>
                  <.input
                    type="number"
                    name="max_cost_in"
                    value={@filters.max_cost_in}
                    placeholder="e.g., 5.00"
                    step="0.01"
                  />
                </div>

                <div>
                  <.form_label>Max Cost Out ($/1M tokens)</.form_label>
                  <.input
                    type="number"
                    name="max_cost_out"
                    value={@filters.max_cost_out}
                    placeholder="e.g., 15.00"
                    step="0.01"
                  />
                </div>
              </form>
            </.card_content>
          </.card>
        </div>
      </div>
    </div>
    """
  end

  # =============================================================================
  # Helper Functions
  # =============================================================================

  defp has_capabilities?(model) do
    caps = model.capabilities || %{}
    map_size(caps) > 0
  end

  defp filtered_providers(providers, search_term) do
    providers
    |> Enum.filter(fn provider ->
      if search_term == "" do
        true
      else
        search_term = String.downcase(search_term)
        String.contains?(String.downcase(to_string(provider.name)), search_term)
      end
    end)
    |> Enum.sort_by(& &1.name)
  end

  defp lifecycle_status(model) do
    nested_get(model, [:lifecycle, :status]) || "active"
  end

  defp lifecycle_label(model) do
    status = lifecycle_status(model)

    cond do
      model.deprecated -> "Deprecated"
      status == "deprecated" -> "Deprecated"
      status == "retired" -> "Retired"
      true -> "Active"
    end
  end

  defp lifecycle_bg_color(model) do
    status = lifecycle_status(model)

    cond do
      model.deprecated -> "--destructive"
      status == "deprecated" -> "--destructive"
      status == "retired" -> "--muted"
      true -> "--secondary"
    end
  end

  defp lifecycle_text_color(model) do
    status = lifecycle_status(model)

    cond do
      model.deprecated -> "--destructive-foreground"
      status == "deprecated" -> "--destructive-foreground"
      status == "retired" -> "--muted-foreground"
      true -> "--secondary-foreground"
    end
  end

  defp embeddings_enabled?(caps) do
    case map_value(caps || %{}, :embeddings) do
      true -> true
      %{} = emb -> map_size(emb) > 0
      _ -> false
    end
  end

  defp has_modalities?(model) do
    modalities = model.modalities || %{}
    input_list = map_value(modalities, :input) || []
    output_list = map_value(modalities, :output) || []
    length(input_list) > 0 or length(output_list) > 0
  end
end

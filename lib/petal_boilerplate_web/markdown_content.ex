defmodule PetalBoilerplateWeb.MarkdownContent do
  @moduledoc """
  Builds deterministic Markdown representations of public pages.
  """

  alias PetalBoilerplate.Catalog
  alias PetalBoilerplate.Catalog.LandingPages
  alias PetalBoilerplate.Catalog.LLMModelsList
  alias PetalBoilerplate.SEOContent
  alias PetalBoilerplateWeb.LandingLinks
  alias PetalBoilerplateWeb.PublicRoutes

  @history_limit 50

  @spec eligible_public_path?(String.t()) :: boolean()
  def eligible_public_path?(path)
      when path in ["/", "/about", "/developers", "/history", "/llm-models", "/privacy"],
      do: true

  def eligible_public_path?(path) when is_binary(path) do
    not is_nil(SEOContent.get_page(path)) or
      match?({:ok, _model}, PublicRoutes.model_from_path(path))
  end

  @spec resolve(String.t(), String.t()) :: {:ok, String.t()} | :no_match
  def resolve("/", canonical_url), do: {:ok, home_markdown(canonical_url)}
  def resolve("/about", canonical_url), do: {:ok, about_markdown(canonical_url)}
  def resolve("/developers", canonical_url), do: {:ok, developers_markdown(canonical_url)}
  def resolve("/history", canonical_url), do: {:ok, history_markdown(canonical_url)}
  def resolve("/llm-models", canonical_url), do: {:ok, llm_models_markdown(canonical_url)}
  def resolve("/privacy", canonical_url), do: {:ok, privacy_markdown(canonical_url)}

  def resolve(path, canonical_url) do
    with nil <- SEOContent.get_page(path) do
      case PublicRoutes.model_from_path(path) do
        {:ok, model} -> {:ok, model_markdown(model, canonical_url)}
        :error -> :no_match
      end
    else
      page ->
        case LandingPages.action_for_route(page.route) do
          {:ok, action} -> {:ok, catalog_landing_markdown(action, page, canonical_url)}
          :error -> :no_match
        end
    end
  end

  defp home_markdown(canonical_url) do
    model_count = Catalog.total_model_count()
    provider_count = length(Catalog.list_providers())
    endpoint_url = PetalBoilerplateWeb.Endpoint.url()

    """
    # LLM Catalog by Jidoka Labs

    Browse and compare #{Catalog.format_number(model_count)} large language models from #{provider_count} providers.

    Filter models by provider, capabilities, pricing, modalities, context windows, and output limits.

    - [Browse models](#{canonical_url})
    - [Deduplicated LLM models list](#{endpoint_url}/llm-models)
    - [AI model rankings](#{endpoint_url}/rankings/ai-models)
    - [Cheapest LLM APIs](#{endpoint_url}/rankings/cheapest-llm-api)
    - [Zero-price LLM API offers](#{endpoint_url}/rankings/free-llm-api)
    - [Vision LLM models](#{endpoint_url}/models/vision)
    - [Tool-calling LLM models](#{endpoint_url}/models/tool-calling)
    - [Largest context window LLMs](#{endpoint_url}/models/long-context)
    - [Open-weight LLM models](#{endpoint_url}/models/open-weights)
    - [Video AI models](#{endpoint_url}/models/video)
    - [About LLM Catalog](#{endpoint_url}/about)
    - [Developer guide](#{endpoint_url}/developers)
    - [Privacy policy](#{endpoint_url}/privacy)
    - [Recent model history](#{endpoint_url}/history)
    - [XML sitemap](#{endpoint_url}/sitemap.xml)
    - [RSS history feed](#{endpoint_url}/feed)
    - [LLM retrieval guidance](#{endpoint_url}/llms.txt)
    - [OpenAPI document](#{endpoint_url}/openapi.json)
    - Tool endpoint: `POST #{endpoint_url}/api/mcp`
    """
  end

  defp about_markdown(canonical_url) do
    model_count = Catalog.total_model_count()
    provider_count = length(Catalog.list_providers())

    """
    # About LLM Catalog

    LLM Catalog is a database of #{Catalog.format_number(model_count)} large language models from #{provider_count} providers.

    The catalog supports comparisons of model capabilities, pricing, context windows, output limits, modalities, aliases, and lifecycle data.

    The site uses the open-source `llmdb` project as its catalog source.

    Canonical URL: #{canonical_url}
    """
  end

  defp history_markdown(canonical_url) do
    events =
      case history_module().recent(@history_limit) do
        {:ok, events} -> events
        _ -> []
      end

    event_markdown =
      case events do
        [] ->
          "History data is not available."

        entries ->
          entries
          |> Enum.map(&format_history_event/1)
          |> Enum.join("\n")
      end

    """
    # Recent LLM Model History

    Reverse-chronological model metadata changes from the bundled `llmdb` history.

    Canonical URL: #{canonical_url}

    ## Latest events

    #{event_markdown}
    """
  end

  defp developers_markdown(canonical_url) do
    endpoint_url = PetalBoilerplateWeb.Endpoint.url()

    """
    # LLM Catalog by Jidoka Labs developer guide

    Use public catalog pages, Markdown copies, history APIs, and lookup tools without an API key.

    ## Choose the right interface

    - Use HTML for interactive browsing and comparison.
    - Use Markdown for compact page content with stable headings and links.
    - Use the history API for metadata changes as JSON.
    - Use the npm package when a Node.js application needs catalog data locally.
    - Verify important prices, limits, and availability with the model provider.

    ## Markdown

    Send `Accept: text/markdown` to a supported public page or add `.md` to its path.

    ## JSON APIs

    - `GET #{endpoint_url}/api/history/recent?limit=25`
    - `GET #{endpoint_url}/api/history/:provider/:model_id?limit=100`
    - [OpenAPI 3.1 document](#{endpoint_url}/openapi.json)

    API errors use `application/problem+json` and include `code`, `status`, `detail`, `instance`, and `resolution` fields.

    ## Catalog lookup tools

    `POST #{endpoint_url}/api/mcp` accepts `tools/list` and `tools/call`. Tools are `query_models`, `get_model`, and `list_providers`. This is a small tool interface, not a complete MCP protocol server.

    ## JavaScript package

    Install [`@agentjido/llmdb`](https://www.npmjs.com/package/@agentjido/llmdb) with `npm install @agentjido/llmdb`. The package does not currently install a command-line executable.

    Canonical URL: #{canonical_url}
    """
  end

  defp privacy_markdown(canonical_url) do
    """
    # LLM Catalog by Jidoka Labs privacy policy

    Effective August 25, 2026.

    LLM Catalog is a public website without user accounts. Standard server request data can be processed for security, fault diagnosis, and service operation.

    When analytics are enabled, the site uses cookieless Plausible Analytics through first-party proxy paths. Exact searches for catalog provider names or IDs, model names, or model IDs are sent as canonical catalog labels. Every other search is recorded only as `other`; unmatched text is not sent. Analytics are disabled in local development by default.

    The site can use a signed session cookie and stores the selected color theme in browser local storage. It does not use advertising cookies.

    The site does not sell personal data or use it for advertising. For questions, use the [LLM Catalog GitHub issue tracker](https://github.com/agentjido/llmcatalog/issues) and do not include sensitive data in a public issue.

    Canonical URL: #{canonical_url}
    """
  end

  defp llm_models_markdown(canonical_url) do
    snapshot = LLMModelsList.snapshot()
    page = SEOContent.get_page!("/llm-models")

    rows =
      snapshot.entries
      |> Enum.map(fn entry ->
        model_url = PublicRoutes.absolute(PublicRoutes.model_path(entry.representative))

        "| [#{markdown_escape(entry.name)}](#{model_url}) | `#{markdown_escape(entry.model_id)}` | #{entry.provider_count} | #{number_or_na(entry.context)} | #{cost_or_na(entry.cost_in)} / #{cost_or_na(entry.cost_out)} | #{value_or_na(entry.last_updated)} |"
      end)
      |> Enum.join("\n")

    """
    # #{page.title}

    #{page.description}

    - Active LLM model IDs: #{Catalog.format_number(snapshot.model_identity_count)}
    - Executable provider offers: #{Catalog.format_number(snapshot.eligible_offer_count)}
    - API providers: #{snapshot.provider_count}
    - Complete catalog records: #{Catalog.format_number(snapshot.catalog_offer_count)}
    - Latest recorded update: #{value_or_na(snapshot.last_updated)}

    #{methodology_markdown(page.methodology)}

    #{String.trim(page.markdown)}

    #{sources_markdown(page.sources)}

    ## Recently updated models

    | Model | Model ID | Offers | Context | Input / output per 1M tokens | Updated |
    | --- | --- | ---: | ---: | ---: | --- |
    #{rows}

    #{LandingLinks.markdown_for(page.route)}

    Canonical URL: #{canonical_url}

    Full catalog: #{PetalBoilerplateWeb.Endpoint.url()}/

    MCP endpoint: `#{PetalBoilerplateWeb.Endpoint.url()}/api/mcp`
    """
  end

  defp model_markdown(model, canonical_url) do
    model_id = model.model_id
    title = model.name || model_id

    """
    # #{title}

    - Provider: #{model.provider}
    - Model ID: `#{model_id}`
    - Family: #{value_or_na(model.family)}
    - Deprecated: #{yes_no(model.deprecated)}
    - Release date: #{value_or_na(Map.get(model, :release_date))}
    - Last updated: #{value_or_na(Map.get(model, :last_updated))}
    - Context window: #{number_or_na(Map.get(model, :__context))}
    - Maximum output: #{number_or_na(Map.get(model, :__output))}
    - Input cost per million tokens: #{cost_or_na(Map.get(model, :__cost_in))}
    - Output cost per million tokens: #{cost_or_na(Map.get(model, :__cost_out))}
    - Input modalities: #{list_or_na(Map.get(model, :__in))}
    - Output modalities: #{list_or_na(Map.get(model, :__out))}
    - Capabilities: #{list_or_na(Map.get(model, :__caps))}
    - Aliases: #{list_or_na(model.aliases)}
    - Tags: #{list_or_na(model.tags)}

    Canonical URL: #{canonical_url}
    """
  end

  defp catalog_landing_markdown(action, page, canonical_url) do
    snapshot = LandingPages.snapshot(action, 1)

    sections =
      snapshot.sections
      |> Enum.map_join("\n\n", fn section ->
        rows =
          section.entries
          |> Enum.map_join("\n", fn entry ->
            model_url = PublicRoutes.absolute(PublicRoutes.model_path(entry.representative))
            providers = entry.providers |> Enum.join(", ") |> markdown_escape()

            "| [#{markdown_escape(entry.name)}](#{model_url}) | `#{markdown_escape(entry.model_id)}` | #{providers} | #{markdown_escape(entry.reason)} | #{number_or_na(entry.context)} | #{landing_price(entry, action)} | #{value_or_na(entry.last_updated)} |"
          end)

        """
        ## #{section.title}

        #{section.description}

        Showing #{length(section.entries)} of #{section.total_count} records.

        | Model | Model ID | Providers | Why listed | Context | Input / output price | Updated |
        | --- | --- | --- | --- | ---: | ---: | --- |
        #{rows}
        """
        |> String.trim()
      end)

    """
    # #{page.title}

    #{page.description}

    - #{page.search.primary_keyword}
    - Records in this view: #{Catalog.format_number(snapshot.total_count)}
    - Providers shown: #{snapshot.provider_count}
    - Latest recorded update: #{value_or_na(snapshot.last_updated)}

    #{methodology_markdown(page.methodology)}

    #{String.trim(page.markdown)}

    #{sections}

    #{sources_markdown(page.sources)}

    #{LandingLinks.markdown_for(page.route)}

    Canonical URL: #{canonical_url}

    MCP endpoint: `#{PetalBoilerplateWeb.Endpoint.url()}/api/mcp`
    """
  end

  defp landing_price(_entry, :video), do: "See model record"

  defp landing_price(entry, _action) do
    "#{cost_or_na(entry.cost_in)} / #{cost_or_na(entry.cost_out)}"
  end

  defp methodology_markdown(methodology) do
    inclusion = markdown_list(methodology.inclusion_criteria)
    exclusions = optional_markdown_section("### Exclusions", methodology.exclusion_criteria)

    rules =
      methodology.rules
      |> Enum.map_join("\n", fn rule ->
        "- **#{rule.label}:** #{rule.description}"
      end)

    caveats = optional_markdown_section("### Limits of the data", methodology.caveats)

    """
    ## #{methodology.name}

    #{methodology.summary}

    ### Inclusion criteria

    #{inclusion}

    #{exclusions}

    ### Data rules

    #{rules}

    #{caveats}
    """
    |> String.trim()
  end

  defp sources_markdown(sources) do
    items =
      Enum.map_join(sources, "\n", fn source ->
        note = if source.note, do: " — #{source.note}", else: ""

        "- [#{source.name}](#{source.url})#{note} Checked #{Date.to_iso8601(source.retrieved_at)}."
      end)

    """
    ## Sources

    #{items}

    See [About LLM Catalog](#{PetalBoilerplateWeb.Endpoint.url()}/about) for more information about the data.
    """
    |> String.trim()
  end

  defp optional_markdown_section(_heading, []), do: ""

  defp optional_markdown_section(heading, items) do
    """
    #{heading}

    #{markdown_list(items)}
    """
    |> String.trim()
  end

  defp markdown_list(items), do: Enum.map_join(items, "\n", &"- #{&1}")

  defp format_history_event(event) do
    provider = map_get(event, "provider", :provider) || "unknown"
    model_id = map_get(event, "model_id", :model_id) || "unknown"
    event_type = map_get(event, "type", :type) || "changed"
    captured_at = map_get(event, "captured_at", :captured_at) || "unknown time"
    model_url = PublicRoutes.absolute(PublicRoutes.model_path(provider, model_id))

    changes =
      event
      |> map_get("changes", :changes)
      |> List.wrap()
      |> Enum.map(fn change ->
        operation = map_get(change, "op", :op) || "changed"
        path = map_get(change, "path", :path) || "model"
        "`#{path}` #{operation}"
      end)
      |> case do
        [] -> "model record"
        items -> Enum.join(items, ", ")
      end

    "- **#{Phoenix.Naming.humanize(event_type)}** [#{provider}:#{model_id}](#{model_url}) at #{captured_at}: #{changes}"
  end

  defp value_or_na(value) when value in [nil, ""], do: "N/A"
  defp value_or_na(value), do: to_string(value)

  defp number_or_na(value) when is_integer(value) and value > 0, do: Catalog.format_number(value)
  defp number_or_na(_value), do: "N/A"

  defp cost_or_na(value) when is_number(value) and value >= 0, do: Catalog.format_cost(value)
  defp cost_or_na(_value), do: "N/A"

  defp yes_no(true), do: "Yes"
  defp yes_no(_value), do: "No"

  defp list_or_na(%MapSet{} = values), do: values |> MapSet.to_list() |> list_or_na()
  defp list_or_na([]), do: "N/A"
  defp list_or_na(nil), do: "N/A"
  defp list_or_na(values) when is_list(values), do: values |> Enum.map_join(", ", &to_string/1)
  defp list_or_na(value), do: to_string(value)

  defp markdown_escape(value) do
    value
    |> to_string()
    |> String.replace("\\", "\\\\")
    |> String.replace("|", "\\|")
    |> String.replace("`", "\\`")
  end

  defp map_get(nil, _string_key, _atom_key), do: nil

  defp map_get(map, string_key, atom_key) do
    Map.get(map, string_key) || Map.get(map, atom_key)
  end

  defp history_module do
    Application.get_env(:petal_boilerplate, :history_module, PetalBoilerplate.History)
  end
end

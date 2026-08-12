defmodule PetalBoilerplateWeb.ModelLive do
  use PetalBoilerplateWeb, :live_view

  alias PetalBoilerplate.Catalog
  alias PetalBoilerplate.Catalog.Filters
  alias PetalBoilerplateWeb.PublicRoutes
  alias PetalBoilerplateWeb.SEO

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :show, %{"provider" => provider, "id" => id_parts}) do
    # *id catch-all gives us a list of path segments — join them back with "/"
    id =
      case id_parts do
        parts when is_list(parts) -> Enum.join(parts, "/")
        str when is_binary(str) -> str
      end

    model = Catalog.get_model(provider, id)

    {history_events, history_meta, history_available} = load_history(model, provider, id)
    history_api_url = if model, do: build_history_api_url(provider, id), else: nil

    socket
    |> assign_og_meta(:show, model)
    |> assign(
      selected_model: model,
      history_events: history_events,
      history_meta: history_meta,
      history_available: history_available,
      history_api_url: history_api_url
    )
  end

  defp apply_action(socket, :index, params) do
    filters = Filters.from_params(params)
    sort = sort_from_params(params)

    socket =
      socket
      |> assign_og_meta(:index, nil, params)
      |> assign(selected_model: nil)
      |> clear_history_assigns()

    if socket.assigns.filters == filters and socket.assigns.sort == sort do
      socket
    else
      apply_filters(socket, filters, sort: sort)
    end
  end

  @sort_fields %{
    "provider" => :provider,
    "id" => :id,
    "name" => :name,
    "family" => :family,
    "context" => :context,
    "output" => :output,
    "cost_in" => :cost_in,
    "cost_out" => :cost_out,
    "total_parameters" => :total_parameters,
    "active_parameters" => :active_parameters,
    "minimum_ram_gb" => :minimum_ram_gb,
    "minimum_vram_gb" => :minimum_vram_gb,
    "recently_changed" => :recently_changed
  }

  @sort_presets %{
    "default" => %{by: :recently_changed, dir: :desc},
    "provider" => %{by: :provider, dir: :asc},
    "total_parameters_asc" => %{by: :total_parameters, dir: :asc},
    "total_parameters_desc" => %{by: :total_parameters, dir: :desc},
    "active_parameters_asc" => %{by: :active_parameters, dir: :asc},
    "active_parameters_desc" => %{by: :active_parameters, dir: :desc},
    "minimum_ram_gb_asc" => %{by: :minimum_ram_gb, dir: :asc},
    "minimum_ram_gb_desc" => %{by: :minimum_ram_gb, dir: :desc},
    "minimum_vram_gb_asc" => %{by: :minimum_vram_gb, dir: :asc},
    "minimum_vram_gb_desc" => %{by: :minimum_vram_gb, dir: :desc}
  }

  @analytics_search_max_length 100
  @analytics_private_search_patterns [
    ~r/@/u,
    ~r/\b(?:https?:\/\/|www\.)/iu,
    ~r/\b(?:\+?\d[\d\s().-]{7,}\d)\b/u,
    ~r/\b(?:\d{1,3}\.){3}\d{1,3}\b/u
  ]
  @analytics_filter_changes [
    {"q", "search"},
    {"providers", "providers"},
    {"caps", "capabilities"},
    {"in", "input_modalities"},
    {"out", "output_modalities"},
    {"architecture", "architecture"},
    {"changed", "changed_within"},
    {"ctx", "min_context"},
    {"min_output", "min_output"},
    {"cost", "max_input_cost"},
    {"max_cost_out", "max_output_cost"},
    {"show_deprecated", "show_deprecated"},
    {"allowed_only", "allowed_only"}
  ]

  @impl true
  def mount(params, _session, socket) do
    filters = Filters.from_params(params)
    sort = sort_from_params(params)
    providers = Catalog.list_providers()
    {page_models, total, total_pages, page} = Catalog.query_models(filters, sort, 1)

    {:ok,
     socket
     |> assign_og_meta(:index, nil, params)
     |> assign(
       providers: providers,
       models: page_models,
       catalog_total: Catalog.total_model_count(),
       filters: filters,
       sort: sort,
       total: total,
       page: page,
       total_pages: total_pages,
       filters_open: false,
       search_value: filters.search,
       active_filter_count: Filters.active_filter_count(filters),
       active_quick_filters: Filters.active_quick_filters(filters),
       selected_model: nil,
       history_events: [],
       history_meta: %{},
       history_available: false,
       history_api_url: nil,
       selected_ids: MapSet.new(),
       comparison_open: false
     )}
  end

  @impl true
  def handle_event("filter", params, socket) do
    filters = merge_filters(socket.assigns.filters, params)
    {:noreply, apply_filters(socket, filters, push_url: true)}
  end

  @impl true
  def handle_event("toggle_filters", _params, socket) do
    {:noreply, assign(socket, filters_open: !socket.assigns.filters_open)}
  end

  @impl true
  def handle_event("sort", %{"by" => field_str}, socket) do
    field = Map.fetch!(@sort_fields, field_str)
    current_sort = socket.assigns.sort

    new_sort =
      if current_sort.by == field do
        %{by: field, dir: toggle_direction(current_sort.dir)}
      else
        %{by: field, dir: :asc}
      end

    {:noreply, apply_filters(socket, socket.assigns.filters, sort: new_sort, push_url: true)}
  end

  @impl true
  def handle_event("page", %{"page" => page_str}, socket) do
    page = String.to_integer(page_str)

    {page_models, total, total_pages, page} =
      Catalog.query_models(socket.assigns.filters, socket.assigns.sort, page)

    {:noreply,
     assign(socket,
       models: page_models,
       page: page,
       total: total,
       total_pages: total_pages
     )}
  end

  @impl true
  def handle_event("show_model", %{"id" => dom_id}, socket) do
    model = Catalog.get_model_by_dom_id(dom_id)

    if model do
      path = model_show_path(model)
      {:noreply, push_patch(socket, to: path)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("close_model", _params, socket) do
    {:noreply, push_patch(socket, to: index_path(socket.assigns.filters, socket.assigns.sort))}
  end

  @impl true
  def handle_event("toggle_select", %{"id" => id}, socket) do
    selected_ids = socket.assigns.selected_ids
    max_selection = 4

    selected_ids =
      if MapSet.member?(selected_ids, id) do
        MapSet.delete(selected_ids, id)
      else
        if MapSet.size(selected_ids) < max_selection do
          MapSet.put(selected_ids, id)
        else
          selected_ids
        end
      end

    {:noreply, assign(socket, selected_ids: selected_ids)}
  end

  @impl true
  def handle_event("open_comparison", _params, socket) do
    {:noreply, assign(socket, comparison_open: true)}
  end

  @impl true
  def handle_event("close_comparison", _params, socket) do
    {:noreply, assign(socket, comparison_open: false)}
  end

  @impl true
  def handle_event("clear_comparison", _params, socket) do
    {:noreply, assign(socket, selected_ids: MapSet.new(), comparison_open: false)}
  end

  @impl true
  def handle_event("remove_from_comparison", %{"id" => id}, socket) do
    {:noreply, assign(socket, selected_ids: MapSet.delete(socket.assigns.selected_ids, id))}
  end

  @impl true
  def handle_event("quick_filter", %{"kind" => kind}, socket) do
    filters = Filters.apply_quick_filter(socket.assigns.filters, kind)
    {:noreply, apply_filters(socket, filters, push_url: true)}
  end

  @impl true
  def handle_event("clear_search", _params, socket) do
    filters = Filters.set_search(socket.assigns.filters, "")
    {:noreply, apply_filters(socket, filters, push_url: true)}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    filters = Filters.set_search(Filters.new(), socket.assigns.filters.search)
    {:noreply, apply_filters(socket, filters, push_url: true)}
  end

  @impl true
  def handle_event("reset_filters", _params, socket) do
    {:noreply, apply_filters(socket, Filters.new(), push_url: true)}
  end

  @impl true
  def handle_event("select_all_providers", _params, socket) do
    all_provider_ids = MapSet.new(Enum.map(socket.assigns.providers, &to_string(&1.id)))
    filters = Filters.set_providers(socket.assigns.filters, all_provider_ids)
    {:noreply, apply_filters(socket, filters, push_url: true)}
  end

  @impl true
  def handle_event("clear_providers", _params, socket) do
    filters = Filters.clear_providers(socket.assigns.filters)
    {:noreply, apply_filters(socket, filters, push_url: true)}
  end

  @impl true
  def handle_event("toggle_provider", %{"id" => id}, socket) do
    filters = socket.assigns.filters
    provider_ids = filters.provider_ids

    new_ids =
      if MapSet.member?(provider_ids, id) do
        MapSet.delete(provider_ids, id)
      else
        MapSet.put(provider_ids, id)
      end

    filters = Filters.set_providers(filters, new_ids)
    {:noreply, apply_filters(socket, filters, push_url: true)}
  end

  @impl true
  def handle_event("remove_provider", %{"id" => id}, socket) do
    filters = socket.assigns.filters
    new_ids = MapSet.delete(filters.provider_ids, id)
    filters = Filters.set_providers(filters, new_ids)
    {:noreply, apply_filters(socket, filters, push_url: true)}
  end

  @impl true
  def handle_event("provider_search", %{"provider_search" => term}, socket) do
    filters = Filters.set_provider_search(socket.assigns.filters, term)
    {:noreply, apply_filters(socket, filters)}
  end

  @impl true
  def handle_event("remove_filter", %{"kind" => kind} = params, socket) do
    filters = socket.assigns.filters

    filters =
      case kind do
        "provider" ->
          id = params["filter_value"]
          Filters.set_providers(filters, MapSet.delete(filters.provider_ids, id))

        "capability" ->
          if params["filter_value"] && params["filter_value"] != "" do
            cap = String.to_existing_atom(params["filter_value"])
            %{filters | capabilities: Map.put(filters.capabilities, cap, false)}
          else
            filters
          end

        "modality_in" ->
          mod = String.to_existing_atom(params["filter_value"])
          Filters.toggle_modality_in(filters, mod)

        "modality_out" ->
          mod = String.to_existing_atom(params["filter_value"])
          Filters.toggle_modality_out(filters, mod)

        "architecture" ->
          Filters.set_architecture(filters, :all)

        "changed_within" ->
          Filters.set_changed_within(filters, nil)

        "min_context" ->
          Filters.set_context_min(filters, nil)

        "min_output" ->
          Filters.set_output_min(filters, nil)

        "max_cost_in" ->
          Filters.set_cost_max(filters, :input, nil)

        "max_cost_out" ->
          Filters.set_cost_max(filters, :output, nil)

        "show_deprecated" ->
          %{filters | show_deprecated: false}

        "allowed_only" ->
          %{filters | allowed_only: true}

        _ ->
          filters
      end

    {:noreply, apply_filters(socket, filters, push_url: true)}
  end

  @impl true
  def handle_event("set_min_context", %{"value" => value}, socket) do
    context_value = parse_int_value(value)
    filters = Filters.set_context_min(socket.assigns.filters, context_value)
    {:noreply, apply_filters(socket, filters, push_url: true)}
  end

  @impl true
  def handle_event("set_changed_within", %{"changed_within" => value}, socket) do
    changed_within_days =
      case parse_int_value(value) do
        days when is_integer(days) and days > 0 -> days
        _ -> nil
      end

    filters = Filters.set_changed_within(socket.assigns.filters, changed_within_days)
    {:noreply, apply_filters(socket, filters, push_url: true)}
  end

  @impl true
  def handle_event("set_max_cost", %{"value" => value}, socket) do
    cost_value = parse_float_value(value)
    filters = Filters.set_cost_max(socket.assigns.filters, :input, cost_value)
    {:noreply, apply_filters(socket, filters, push_url: true)}
  end

  @impl true
  def handle_event("set_sort", %{"sort" => sort_key}, socket) do
    sort = Map.get(@sort_presets, sort_key, socket.assigns.sort)

    {:noreply, apply_filters(socket, socket.assigns.filters, sort: sort, push_url: true)}
  end

  defp toggle_direction(:asc), do: :desc
  defp toggle_direction(:desc), do: :asc

  defp apply_filters(socket, %Filters{} = filters, opts \\ []) do
    previous_filters = socket.assigns.filters
    previous_sort = socket.assigns.sort
    sort = Keyword.get(opts, :sort, socket.assigns.sort)
    page = Keyword.get(opts, :page, 1)
    {page_models, total, total_pages, page} = Catalog.query_models(filters, sort, page)

    socket =
      socket
      |> assign(
        models: page_models,
        filters: filters,
        sort: sort,
        total: total,
        page: page,
        total_pages: total_pages,
        search_value: filters.search,
        active_filter_count: Filters.active_filter_count(filters),
        active_quick_filters: Filters.active_quick_filters(filters)
      )

    if Keyword.get(opts, :push_url, false) do
      socket
      |> maybe_track_catalog_change(previous_filters, previous_sort, filters, sort, total)
      |> push_patch(to: index_path(filters, sort), replace: true)
    else
      socket
    end
  end

  defp maybe_track_catalog_change(
         socket,
         previous_filters,
         previous_sort,
         filters,
         sort,
         total
       ) do
    changes = analytics_changes(previous_filters, previous_sort, filters, sort)

    with true <- Application.get_env(:petal_boilerplate, :enable_analytics, false),
         event_name when is_binary(event_name) <- analytics_event_name(changes, filters) do
      push_event(socket, "plausible-event", %{
        name: event_name,
        props: analytics_event_props(filters, sort, total, changes)
      })
    else
      _ -> socket
    end
  end

  defp analytics_changes(previous_filters, previous_sort, filters, sort) do
    previous_params = Filters.to_params(previous_filters)
    current_params = Filters.to_params(filters)

    changes =
      Enum.flat_map(@analytics_filter_changes, fn {param, change} ->
        if Map.get(previous_params, param) == Map.get(current_params, param) do
          []
        else
          [change]
        end
      end)

    if previous_sort == sort, do: changes, else: changes ++ ["sort"]
  end

  defp analytics_event_name([], _filters), do: nil

  defp analytics_event_name(changes, filters) do
    cond do
      "search" in changes and String.trim(filters.search) != "" -> "Model Search"
      Enum.any?(changes, &(&1 != "search")) -> "Model Filter"
      true -> nil
    end
  end

  defp analytics_event_props(filters, sort, total, changes) do
    %{
      action: Enum.join(changes, ","),
      query: analytics_search_value(filters.search),
      providers: analytics_list_value(filters.provider_ids),
      provider_count: MapSet.size(filters.provider_ids),
      capabilities: analytics_capabilities_value(filters.capabilities),
      input_modalities: analytics_list_value(filters.modalities_in),
      output_modalities: analytics_list_value(filters.modalities_out),
      architecture: Atom.to_string(filters.architecture),
      changed_within_days: analytics_scalar_value(filters.changed_within_days),
      min_context: analytics_scalar_value(filters.min_context),
      min_output: analytics_scalar_value(filters.min_output),
      max_input_cost: analytics_scalar_value(filters.max_cost_in),
      max_output_cost: analytics_scalar_value(filters.max_cost_out),
      show_deprecated: filters.show_deprecated,
      allowed_only: filters.allowed_only,
      sort_by: Atom.to_string(sort.by),
      sort_direction: Atom.to_string(sort.dir),
      result_count: total,
      active_filter_count: Filters.active_filter_count(filters)
    }
  end

  defp analytics_search_value(search) do
    normalized_search =
      search
      |> String.trim()
      |> String.replace(~r/\s+/u, " ")

    cond do
      normalized_search == "" ->
        "none"

      Enum.any?(@analytics_private_search_patterns, &Regex.match?(&1, normalized_search)) ->
        "redacted"

      true ->
        String.slice(normalized_search, 0, @analytics_search_max_length)
    end
  end

  defp analytics_capabilities_value(capabilities) do
    capabilities
    |> Enum.filter(fn {_capability, enabled} -> enabled end)
    |> Enum.map(fn {capability, _enabled} -> capability end)
    |> analytics_list_value()
  end

  defp analytics_list_value(values) do
    values =
      values
      |> Enum.map(&to_string/1)
      |> Enum.sort()

    case values do
      [] ->
        "none"

      values ->
        joined_values = Enum.join(values, ",")

        if String.length(joined_values) > 500, do: "many", else: joined_values
    end
  end

  defp analytics_scalar_value(nil), do: "none"
  defp analytics_scalar_value(value), do: value

  defp selected_models(assigns) do
    assigns.selected_ids
    |> MapSet.to_list()
    |> Enum.map(&Catalog.get_model_by_dom_id/1)
    |> Enum.reject(&is_nil/1)
  end

  defp clear_history_assigns(socket) do
    assign(socket,
      history_events: [],
      history_meta: %{},
      history_available: false,
      history_api_url: nil
    )
  end

  defp load_history(nil, _provider, _model_id), do: {[], %{}, false}

  defp load_history(_model, provider, model_id) do
    history = history_module()

    with {:ok, events} <- history.timeline(provider, model_id, 200),
         {:ok, meta} <- history.meta() do
      {events, meta, true}
    else
      _ -> {[], %{}, false}
    end
  end

  defp build_history_api_url(provider, model_id) do
    encoded_provider = URI.encode(provider)

    encoded_model_id =
      model_id
      |> String.split("/")
      |> Enum.map(&URI.encode/1)
      |> Enum.join("/")

    "/api/history/#{encoded_provider}/#{encoded_model_id}?limit=200"
  end

  defp model_show_path(model) do
    PublicRoutes.model_path(model)
  end

  defp history_module do
    Application.get_env(:petal_boilerplate, :history_module, PetalBoilerplate.History)
  end

  defp index_path(filters, sort) do
    query_params =
      filters
      |> Filters.to_params()
      |> maybe_put_sort(sort)

    query_string =
      query_params
      |> Enum.sort_by(fn {key, _value} -> key end)
      |> Enum.map(fn {key, value} ->
        URI.encode(to_string(key)) <> "=" <> URI.encode(to_string(value))
      end)
      |> Enum.join("&")

    if query_string == "", do: "/", else: "/?" <> query_string
  end

  defp maybe_put_sort(params, sort) do
    if sort == Catalog.default_sort() do
      params
    else
      params
      |> Map.put("sort", sort_param(sort.by))
      |> Map.put("dir", Atom.to_string(sort.dir))
    end
  end

  defp sort_from_params(params) do
    with sort_key when is_binary(sort_key) <- Map.get(params, "sort"),
         {:ok, field} <- fetch_sort_field(sort_key) do
      %{by: field, dir: parse_sort_direction(Map.get(params, "dir"), field)}
    else
      _ -> Catalog.default_sort()
    end
  end

  defp fetch_sort_field(sort_key) when is_binary(sort_key) do
    case Map.fetch(@sort_fields, sort_key) do
      {:ok, field} -> {:ok, field}
      :error -> :error
    end
  end

  defp parse_sort_direction("desc", _field), do: :desc
  defp parse_sort_direction("asc", _field), do: :asc
  defp parse_sort_direction(_value, :recently_changed), do: :desc
  defp parse_sort_direction(_value, _field), do: :asc

  defp sort_param(field) do
    Enum.find_value(@sort_fields, "provider", fn {param, mapped_field} ->
      if mapped_field == field, do: param
    end)
  end

  defp sort_control_value(sort) do
    cond do
      sort == Catalog.default_sort() ->
        "default"

      sort == %{by: :provider, dir: :asc} ->
        "provider"

      sort.by in [:total_parameters, :active_parameters, :minimum_ram_gb, :minimum_vram_gb] ->
        "#{sort.by}_#{sort.dir}"

      true ->
        "custom"
    end
  end

  defp parse_int_value(""), do: nil
  defp parse_int_value(nil), do: nil

  defp parse_int_value(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      :error -> nil
    end
  end

  defp parse_int_value(value) when is_integer(value), do: value

  defp parse_float_value(""), do: nil
  defp parse_float_value(nil), do: nil

  defp parse_float_value(value) when is_binary(value) do
    case Float.parse(value) do
      {float, _} -> float
      :error -> nil
    end
  end

  defp parse_float_value(value) when is_float(value), do: value
  defp parse_float_value(value) when is_integer(value), do: value * 1.0

  defp merge_filters(%Filters{} = current_filters, params) when is_map(params) do
    target = List.wrap(params["_target"])
    cleaned_params = Map.delete(params, "_target")

    current_filters
    |> current_filter_params()
    |> drop_replaced_filter_keys(target)
    |> Map.merge(cleaned_params)
    |> Filters.from_params()
  end

  defp current_filter_params(%Filters{} = filters) do
    filters
    |> Filters.to_params()
    |> Map.put("provider_search", filters.provider_search)
  end

  defp drop_replaced_filter_keys(params, ["search"]), do: Map.drop(params, ["q"])

  defp drop_replaced_filter_keys(params, ["provider_search"]),
    do: Map.drop(params, ["provider_search"])

  defp drop_replaced_filter_keys(params, ["changed_within"]), do: Map.drop(params, ["changed"])
  defp drop_replaced_filter_keys(params, ["min_context"]), do: Map.drop(params, ["ctx"])
  defp drop_replaced_filter_keys(params, ["min_output"]), do: Map.drop(params, ["min_output"])
  defp drop_replaced_filter_keys(params, ["max_cost_in"]), do: Map.drop(params, ["cost"])
  defp drop_replaced_filter_keys(params, ["max_cost_out"]), do: Map.drop(params, ["max_cost_out"])

  defp drop_replaced_filter_keys(params, ["show_deprecated"]),
    do: Map.drop(params, ["show_deprecated"])

  defp drop_replaced_filter_keys(params, ["allowed_only"]), do: Map.drop(params, ["allowed_only"])

  defp drop_replaced_filter_keys(params, ["providers", _provider_id]),
    do: Map.drop(params, ["providers"])

  defp drop_replaced_filter_keys(params, ["modalities_in", _modality]),
    do: Map.drop(params, ["in"])

  defp drop_replaced_filter_keys(params, ["modalities_out", _modality]),
    do: Map.drop(params, ["out"])

  defp drop_replaced_filter_keys(params, [field]) when is_binary(field) do
    if String.starts_with?(field, "cap_") do
      Map.drop(params, ["caps"])
    else
      params
    end
  end

  defp drop_replaced_filter_keys(params, _target), do: params

  def format_number(value), do: Catalog.format_number(value)
  def format_cost(value), do: Catalog.format_cost(value)

  defp assign_og_meta(socket, action, model), do: assign_og_meta(socket, action, model, %{})

  defp assign_og_meta(socket, :index, _model, params) do
    model_count = Catalog.total_model_count()
    provider_count = length(Catalog.list_providers())

    assign(socket,
      page_title: "LLM Catalog",
      page_description:
        "Browse and compare #{format_number(model_count)} LLM models. Filter by provider, capabilities, pricing, modalities, and context windows.",
      canonical_url: PublicRoutes.absolute("/"),
      og_image: PublicRoutes.absolute("/og/home.png"),
      robots: if(map_size(params) > 0, do: ["noindex", "follow"]),
      structured_data: SEO.home_structured_data(model_count, provider_count)
    )
  end

  defp assign_og_meta(socket, :show, nil, _params) do
    assign(socket,
      page_title: "Model Not Found",
      page_description: "The requested model could not be found.",
      robots: ["noindex", "nofollow"],
      canonical_url: nil,
      og_image: PublicRoutes.absolute("/og/default.png"),
      structured_data: []
    )
  end

  defp assign_og_meta(socket, :show, model, _params) do
    model_id = Map.get(model, :model_id) || model.id
    title = "#{model.name || model_id} - #{model.provider}"

    description =
      build_model_description(model)

    assign(socket,
      page_title: title,
      page_description: description,
      canonical_url: PublicRoutes.absolute(PublicRoutes.model_path(model.provider, model_id)),
      og_image: PublicRoutes.absolute(PublicRoutes.model_og_path(model.provider, model_id)),
      robots: ["noindex", "follow"],
      structured_data: SEO.model_structured_data(model, description)
    )
  end

  defp build_model_description(model) do
    context = get_model_context(model)
    cost_in = get_model_cost_in(model)
    cost_out = get_model_cost_out(model)
    model_id = Map.get(model, :model_id) || model.id

    parts = []

    parts =
      if context do
        parts ++ ["#{format_number(context)} context"]
      else
        parts
      end

    parts =
      if cost_in do
        parts ++ ["#{Catalog.format_cost(cost_in)}/M input"]
      else
        parts
      end

    parts =
      if cost_out do
        parts ++ ["#{Catalog.format_cost(cost_out)}/M output"]
      else
        parts
      end

    base = "#{model.name || model_id} by #{model.provider}"

    if parts == [] do
      base <> " - View specs and compare with other LLMs on LLM Catalog"
    else
      base <> " - " <> Enum.join(parts, ", ") <> ". Compare LLMs on LLM Catalog"
    end
  end

  defp get_model_context(model) do
    case model do
      %{__context: ctx} when is_integer(ctx) and ctx > 0 -> ctx
      %{limits: %{context: ctx}} when is_integer(ctx) -> ctx
      _ -> nil
    end
  end

  defp get_model_cost_in(model) do
    case model do
      %{__cost_in: cost} when is_number(cost) -> cost
      %{cost: %{input: cost}} when is_number(cost) -> cost
      _ -> nil
    end
  end

  defp get_model_cost_out(model) do
    case model do
      %{__cost_out: cost} when is_number(cost) -> cost
      %{cost: %{output: cost}} when is_number(cost) -> cost
      _ -> nil
    end
  end
end

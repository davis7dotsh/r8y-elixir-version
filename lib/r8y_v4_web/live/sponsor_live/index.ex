defmodule R8yV4Web.SponsorLive.Index do
  @moduledoc """
  Sponsor listing page with stats.
  """
  use R8yV4Web, :live_view

  alias Phoenix.LiveView.JS
  alias R8yV4.Monitoring

  attr :field, :string, required: true
  attr :sort_by, :string, required: true
  attr :sort_dir, :string, required: true

  defp sort_icon(assigns) do
    ~H"""
    <span class="text-xs">
      <%= if @sort_by == @field do %>
        <%= if @sort_dir == "desc" do %>
          <.icon name="hero-chevron-down" class="size-3" />
        <% else %>
          <.icon name="hero-chevron-up" class="size-3" />
        <% end %>
      <% else %>
        <.icon name="hero-chevron-up-down" class="size-3 opacity-30" />
      <% end %>
    </span>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    sort_by = "views"
    sort_dir = "desc"

    sponsors =
      Monitoring.list_sponsors_with_stats(limit: 200, sort_by: sort_by, sort_dir: sort_dir)

    socket =
      socket
      |> assign(:page_title, "Sponsors")
      |> assign(:yt_channel_id, "")
      |> assign(:sort_by, sort_by)
      |> assign(:sort_dir, sort_dir)
      |> assign(:sponsors, sponsors)
      |> assign(:form, to_form(%{"yt_channel_id" => ""}, as: :filter))

    {:ok, socket}
  end

  @impl true
  def handle_event("change", %{"filter" => params}, socket) do
    yt_channel_id = Map.get(params, "yt_channel_id", "")

    sponsors =
      Monitoring.list_sponsors_with_stats(
        yt_channel_id: yt_channel_id,
        sort_by: socket.assigns.sort_by,
        sort_dir: socket.assigns.sort_dir,
        limit: 200
      )

    {:noreply,
     socket
     |> assign(:yt_channel_id, yt_channel_id)
     |> assign(:sponsors, sponsors)
     |> assign(:form, to_form(params, as: :filter))}
  end

  @impl true
  def handle_event("sort", %{"field" => field}, socket) do
    {sort_by, sort_dir} =
      if socket.assigns.sort_by == field do
        new_dir = if socket.assigns.sort_dir == "desc", do: "asc", else: "desc"
        {field, new_dir}
      else
        {field, "desc"}
      end

    sponsors =
      Monitoring.list_sponsors_with_stats(
        yt_channel_id: socket.assigns.yt_channel_id,
        sort_by: sort_by,
        sort_dir: sort_dir,
        limit: 200
      )

    {:noreply,
     socket
     |> assign(:sort_by, sort_by)
     |> assign(:sort_dir, sort_dir)
     |> assign(:sponsors, sponsors)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div id="sponsors-index" class="space-y-6">
        <div class="flex items-start justify-between gap-4">
          <div>
            <h1 class="text-2xl font-semibold text-base-content">Sponsors</h1>
            <p class="text-sm text-base-content/60 mt-1">
              All detected sponsors with performance metrics
            </p>
          </div>
          <.button navigate={~p"/channels"} id="manage-channels">
            <.icon name="hero-tv" class="size-4" /> Channels
          </.button>
        </div>

        <div class="card">
          <h2 class="font-medium text-base-content mb-4">Filter</h2>
          <.form for={@form} id="sponsor-filter-form" phx-change="change">
            <div class="max-w-md">
              <.input
                field={@form[:yt_channel_id]}
                type="text"
                label="Channel ID (optional)"
                placeholder="UC..."
              />
            </div>
          </.form>
        </div>

        <div class="card-scrollable">
          <div class="flex items-center justify-between mb-4 flex-shrink-0">
            <h2 class="font-medium text-base-content">Detected Sponsors</h2>
            <span class="text-xs text-base-content/40">{length(@sponsors)} results</span>
          </div>

          <%= if @sponsors == [] do %>
            <div class="py-12 text-center">
              <.icon name="hero-currency-dollar" class="size-12 text-base-content/10 mx-auto mb-4" />
              <p class="text-base-content/50 mb-2">
                <%= if String.trim(@yt_channel_id) != "" do %>
                  No sponsors found for this channel
                <% else %>
                  No sponsors detected yet
                <% end %>
              </p>
              <p class="text-sm text-base-content/40">
                Run the sync job to populate sponsor data
              </p>
            </div>
          <% else %>
            <div class="overflow-x-auto">
              <table class="w-full text-sm">
                <thead>
                  <tr class="border-b border-base-300">
                    <th
                      class="text-left py-3 px-3 font-medium text-base-content/60 cursor-pointer hover:text-base-content"
                      phx-click="sort"
                      phx-value-field="name"
                    >
                      <span class="flex items-center gap-1">
                        Sponsor
                        <.sort_icon field="name" sort_by={@sort_by} sort_dir={@sort_dir} />
                      </span>
                    </th>
                    <th class="text-left py-3 px-3 font-medium text-base-content/60">
                      Channel
                    </th>
                    <th
                      class="text-left py-3 px-3 font-medium text-base-content/60 cursor-pointer hover:text-base-content"
                      phx-click="sort"
                      phx-value-field="ads"
                    >
                      <span class="flex items-center gap-1">
                        Ads
                        <.sort_icon field="ads" sort_by={@sort_by} sort_dir={@sort_dir} />
                      </span>
                    </th>
                    <th
                      class="text-left py-3 px-3 font-medium text-base-content/60 cursor-pointer hover:text-base-content"
                      phx-click="sort"
                      phx-value-field="views"
                    >
                      <span class="flex items-center gap-1">
                        Views
                        <.sort_icon field="views" sort_by={@sort_by} sort_dir={@sort_dir} />
                      </span>
                    </th>
                    <th class="text-left py-3 px-3 font-medium text-base-content/60">
                      Avg
                    </th>
                    <th
                      class="text-left py-3 px-3 font-medium text-base-content/60 cursor-pointer hover:text-base-content"
                      phx-click="sort"
                      phx-value-field="last_published"
                    >
                      <span class="flex items-center gap-1">
                        Last
                        <.sort_icon field="last_published" sort_by={@sort_by} sort_dir={@sort_dir} />
                      </span>
                    </th>
                  </tr>
                </thead>
                <tbody id="sponsors-table">
                  <tr
                    :for={row <- @sponsors}
                    id={"sponsors-index-sponsor-#{row.sponsor.sponsor_id}"}
                    phx-click={JS.navigate(~p"/sponsors/#{row.sponsor.sponsor_id}")}
                    class="border-b border-base-300/50 hover:bg-base-300/30 cursor-pointer"
                  >
                    <td class="py-3 px-3">
                      <span class="text-primary font-medium">{row.sponsor.name}</span>
                      <p class="text-xs text-base-content/40 mt-1 font-mono truncate max-w-[200px]">
                        {row.sponsor.sponsor_key}
                      </p>
                    </td>
                    <td class="py-3 px-3">
                      <span class="text-sm text-base-content/50 font-mono truncate max-w-[120px] block">
                        {row.sponsor.yt_channel_id}
                      </span>
                    </td>
                    <td class="py-3 px-3">
                      <span class="tabular-nums text-success">{format_number(row.total_videos)}</span>
                    </td>
                    <td class="py-3 px-3">
                      <span class="tabular-nums">{format_number(row.total_views)}</span>
                    </td>
                    <td class="py-3 px-3">
                      <span class="tabular-nums">{format_number(row.avg_views_per_video)}</span>
                    </td>
                    <td class="py-3 px-3">
                      <span class="text-sm tabular-nums text-base-content/60">
                        {format_date(row.last_video_published_at)}
                      </span>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp format_date(nil), do: "—"
  defp format_date(%NaiveDateTime{} = naive), do: Calendar.strftime(naive, "%Y-%m-%d")

  defp format_number(value) when is_integer(value) do
    value
    |> Integer.to_string()
    |> String.replace(~r/\B(?=(\d{3})+(?!\d))/, ",")
  end

  defp format_number(_), do: "0"
end

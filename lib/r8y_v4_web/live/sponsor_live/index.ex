defmodule R8yV4Web.SponsorLive.Index do
  @moduledoc """
  Sponsor listing page with stats.
  """
  use R8yV4Web, :live_view

  alias R8yV4.Monitoring

  @impl true
  def mount(_params, _session, socket) do
    sponsors = Monitoring.list_sponsors_with_stats(limit: 200)

    socket =
      socket
      |> assign(:page_title, "Sponsors")
      |> assign(:yt_channel_id, "")
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
        limit: 200
      )

    {:noreply,
     socket
     |> assign(:yt_channel_id, yt_channel_id)
     |> assign(:sponsors, sponsors)
     |> assign(:form, to_form(params, as: :filter))}
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

        <div class="card">
          <div class="flex items-center justify-between mb-4">
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
            <.table id="sponsors-table" rows={@sponsors} row_item={fn row -> row end}>
              <:col :let={row} label="Sponsor">
                <.link
                  navigate={~p"/sponsors/#{row.sponsor.sponsor_id}"}
                  id={"sponsors-index-sponsor-#{row.sponsor.sponsor_id}"}
                  class="text-primary hover:underline font-medium"
                >
                  {row.sponsor.name}
                </.link>
                <p class="text-xs text-base-content/40 mt-1 font-mono truncate max-w-[200px]">
                  {row.sponsor.sponsor_key}
                </p>
              </:col>
              <:col :let={row} label="Channel">
                <.link
                  navigate={~p"/channels/#{row.sponsor.yt_channel_id}"}
                  class="text-sm text-base-content/50 hover:text-primary transition-colors font-mono truncate max-w-[120px] block"
                >
                  {row.sponsor.yt_channel_id}
                </.link>
              </:col>
              <:col :let={row} label="Ads">
                <span class="tabular-nums text-success">{format_number(row.total_videos)}</span>
              </:col>
              <:col :let={row} label="Views">
                <span class="tabular-nums">{format_number(row.total_views)}</span>
              </:col>
              <:col :let={row} label="Avg">
                <span class="tabular-nums">{format_number(row.avg_views_per_video)}</span>
              </:col>
              <:col :let={row} label="Last">
                <span class="text-sm tabular-nums text-base-content/60">
                  {format_date(row.last_video_published_at)}
                </span>
              </:col>
            </.table>
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

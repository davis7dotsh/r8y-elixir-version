defmodule R8yV4Web.HomeLive do
  @moduledoc """
  Dashboard for R8Y sponsor detection system.
  """
  use R8yV4Web, :live_view

  alias R8yV4.Monitoring

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Dashboard")
      |> assign_stats()

    {:ok, socket}
  end

  defp assign_stats(socket) do
    socket
    |> assign(:channel_count, Monitoring.count_channels())
    |> assign(:video_count, Monitoring.count_videos())
    |> assign(:sponsor_count, Monitoring.count_sponsors())
    |> assign(:recent_videos, Monitoring.list_recent_videos(limit: 8))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-8">
        <div>
          <h1 class="text-2xl font-semibold text-base-content">Dashboard</h1>
          <p class="text-sm text-base-content/60 mt-1">
            YouTube Channel Monitoring & Sponsor Detection
          </p>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <.stat_card
            title="Channels"
            value={@channel_count}
            href={~p"/channels"}
            icon="hero-tv"
          />
          <.stat_card
            title="Videos"
            value={@video_count}
            href={~p"/videos"}
            icon="hero-play"
          />
          <.stat_card
            title="Sponsors"
            value={@sponsor_count}
            href={~p"/sponsors"}
            icon="hero-currency-dollar"
          />
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div class="lg:col-span-2">
            <div class="card">
              <div class="flex items-center justify-between mb-4">
                <h2 class="font-medium text-base-content">Recent Videos</h2>
                <.link navigate={~p"/videos"} class="text-sm text-primary hover:underline">
                  View all
                </.link>
              </div>

              <div class="space-y-1">
                <div :if={@recent_videos == []} class="text-center py-8">
                  <.icon name="hero-inbox" class="size-8 text-base-content/20 mx-auto mb-2" />
                  <p class="text-sm text-base-content/50">No videos synced yet</p>
                  <.link
                    navigate={~p"/channels/new"}
                    class="text-sm text-primary hover:underline mt-2 inline-block"
                  >
                    Add a channel to begin
                  </.link>
                </div>

                <.video_row :for={video <- @recent_videos} video={video} />
              </div>
            </div>
          </div>

          <div class="card">
            <h2 class="font-medium text-base-content mb-4">Quick Actions</h2>

            <div class="space-y-2">
              <.action_link href={~p"/channels/new"} icon="hero-plus">Add Channel</.action_link>
              <.action_link href={~p"/search"} icon="hero-magnifying-glass">Search</.action_link>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  attr :title, :string, required: true
  attr :value, :integer, required: true
  attr :href, :string, required: true
  attr :icon, :string, required: true

  defp stat_card(assigns) do
    ~H"""
    <.link navigate={@href} class="card hover:border-primary/50 transition-colors">
      <div class="flex items-start justify-between">
        <div>
          <p class="text-sm text-base-content/60">{@title}</p>
          <p class="text-3xl font-semibold text-base-content mt-1 tabular-nums">
            {format_number(@value)}
          </p>
        </div>
        <.icon name={@icon} class="size-5 text-base-content/30" />
      </div>
    </.link>
    """
  end

  attr :video, :map, required: true

  defp video_row(assigns) do
    ~H"""
    <.link
      navigate={~p"/videos/#{@video.yt_video_id}"}
      class="flex items-center gap-4 p-3 -mx-3 rounded-lg hover:bg-base-300/50 transition-colors"
    >
      <div class="relative flex-shrink-0">
        <img
          :if={@video.thumbnail_url}
          src={@video.thumbnail_url}
          alt=""
          class="w-24 h-14 object-cover rounded"
        />
        <div
          :if={!@video.thumbnail_url}
          class="w-24 h-14 bg-base-300 rounded flex items-center justify-center"
        >
          <.icon name="hero-film" class="size-6 text-base-content/20" />
        </div>
      </div>

      <div class="flex-1 min-w-0">
        <p class="text-sm text-base-content/80 truncate">{@video.title}</p>
        <div class="flex items-center gap-2 mt-1 text-xs text-base-content/50">
          <span>{if @video.channel, do: @video.channel.name, else: "Unknown"}</span>
          <span>·</span>
          <span>{format_date(@video.published_at)}</span>
        </div>
      </div>

      <div class="hidden sm:block text-right">
        <p class="text-sm tabular-nums text-base-content/60">{format_number(@video.view_count)}</p>
        <p class="text-xs text-base-content/40">views</p>
      </div>
    </.link>
    """
  end

  attr :href, :string, required: true
  attr :icon, :string, required: true
  slot :inner_block, required: true

  defp action_link(assigns) do
    ~H"""
    <.link
      navigate={@href}
      class="flex items-center gap-3 p-3 -mx-3 rounded-lg hover:bg-base-300/50 transition-colors"
    >
      <.icon name={@icon} class="size-4 text-base-content/50" />
      <span class="text-sm text-base-content/70">{render_slot(@inner_block)}</span>
    </.link>
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

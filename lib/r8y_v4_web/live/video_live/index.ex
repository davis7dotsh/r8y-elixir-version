defmodule R8yV4Web.VideoLive.Index do
  @moduledoc """
  Video listing page.
  """
  use R8yV4Web, :live_view

  alias R8yV4.Monitoring

  @impl true
  def mount(_params, _session, socket) do
    videos = Monitoring.list_recent_videos(limit: 50)

    socket =
      socket
      |> assign(:page_title, "Videos")
      |> stream_configure(:videos, dom_id: &("videos-" <> &1.yt_video_id))

    {:ok, stream(socket, :videos, videos)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-6">
        <div class="flex items-start justify-between gap-4">
          <div>
            <h1 class="text-2xl font-semibold text-base-content">Videos</h1>
            <p class="text-sm text-base-content/60 mt-1">
              Recent videos across all monitored channels
            </p>
          </div>
          <.button navigate={~p"/channels"} id="manage-channels">
            <.icon name="hero-tv" class="size-4" /> Channels
          </.button>
        </div>

        <div class="card">
          <div id="videos" phx-update="stream" class="divide-y divide-neutral">
            <div
              id="videos-empty"
              class="hidden only:flex flex-col items-center justify-center py-12 text-center"
            >
              <.icon name="hero-film" class="size-12 text-base-content/10 mb-4" />
              <p class="text-base-content/50 mb-2">No videos synced</p>
              <.link navigate={~p"/channels/new"} class="text-sm text-primary hover:underline">
                Add a channel to begin
              </.link>
            </div>

            <div
              :for={{dom_id, video} <- @streams.videos}
              id={dom_id}
              class="py-4 first:pt-0 last:pb-0"
            >
              <div class="flex items-start gap-4">
                <a
                  href={youtube_video_url(video.yt_video_id)}
                  target="_blank"
                  rel="noopener noreferrer"
                  class="flex-shrink-0"
                >
                  <img
                    :if={video.thumbnail_url}
                    src={video.thumbnail_url}
                    alt=""
                    class="w-32 h-20 object-cover rounded"
                  />
                  <div
                    :if={!video.thumbnail_url}
                    class="w-32 h-20 bg-base-300 rounded flex items-center justify-center"
                  >
                    <.icon name="hero-film" class="size-8 text-base-content/20" />
                  </div>
                </a>

                <div class="flex-1 min-w-0">
                  <.link
                    navigate={~p"/videos/#{video.yt_video_id}"}
                    class="text-base-content hover:text-primary transition-colors line-clamp-2"
                  >
                    {video.title}
                  </.link>

                  <div class="flex items-center gap-2 mt-2 text-sm text-base-content/50">
                    <span>{video.channel && video.channel.name}</span>
                    <span>·</span>
                    <span class="tabular-nums">{format_date(video.published_at)}</span>
                  </div>

                  <div class="flex flex-wrap items-center gap-2 mt-2">
                    <span class="text-xs px-2 py-0.5 rounded bg-base-300 text-base-content/60">
                      {format_number(video.view_count)} views
                    </span>
                    <span class="text-xs px-2 py-0.5 rounded bg-base-300 text-base-content/60">
                      {format_number(video.like_count)} likes
                    </span>
                    <%= if sponsor = Enum.at(video.sponsors || [], 0) do %>
                      <span class="text-xs px-2 py-0.5 rounded bg-success/20 text-success">
                        {sponsor.name}
                      </span>
                    <% end %>
                  </div>
                </div>

                <div class="flex items-center gap-2 flex-shrink-0">
                  <.button
                    navigate={~p"/videos/#{video.yt_video_id}"}
                    id={"details-#{video.yt_video_id}"}
                    variant="primary"
                  >
                    Details
                  </.button>
                  <.button
                    href={youtube_video_url(video.yt_video_id)}
                    id={"open-#{video.yt_video_id}"}
                  >
                    YouTube
                  </.button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp youtube_video_url(yt_video_id), do: "https://www.youtube.com/watch?v=#{yt_video_id}"

  defp format_date(nil), do: "—"
  defp format_date(%NaiveDateTime{} = naive), do: Calendar.strftime(naive, "%Y-%m-%d")

  defp format_number(value) when is_integer(value) do
    value
    |> Integer.to_string()
    |> String.replace(~r/\B(?=(\d{3})+(?!\d))/, ",")
  end

  defp format_number(_), do: "0"
end

defmodule R8yV4Web.SponsorLive.Show do
  @moduledoc """
  Sponsor detail page with videos and mentions.
  """
  use R8yV4Web, :live_view

  alias R8yV4.Monitoring

  @impl true
  def mount(%{"sponsor_id" => sponsor_id}, _session, socket) do
    {:ok,
     socket
     |> assign(:sponsor_id, sponsor_id)
     |> assign(:page_title, "Sponsor")
     |> assign(:details, nil)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    details = Monitoring.get_sponsor_details!(socket.assigns.sponsor_id)

    {:noreply,
     socket
     |> assign(:page_title, details.sponsor.name)
     |> assign(:details, details)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div id="sponsor-show" class="space-y-6">
        <%= if @details do %>
          <div class="flex items-start justify-between gap-4">
            <div class="min-w-0">
              <h1 class="text-2xl font-semibold text-base-content">{@details.sponsor.name}</h1>
              <a
                href={@details.sponsor.sponsor_key}
                target="_blank"
                rel="noopener noreferrer"
                class="text-sm text-base-content/40 hover:text-primary transition-colors truncate block mt-1"
              >
                {@details.sponsor.sponsor_key}
              </a>
            </div>
            <.button navigate={~p"/channels/#{@details.sponsor.yt_channel_id}"} id="back-to-channel">
              <.icon name="hero-arrow-left" class="size-4" /> Channel
            </.button>
          </div>

          <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div class="card">
              <p class="text-sm text-base-content/60">Total Ads</p>
              <p class="text-2xl font-semibold text-base-content tabular-nums mt-1">
                {format_number(@details.stats.total_ads)}
              </p>
            </div>
            <div class="card">
              <p class="text-sm text-base-content/60">Total Views</p>
              <p class="text-2xl font-semibold text-base-content tabular-nums mt-1">
                {format_number(@details.stats.total_views)}
              </p>
            </div>
            <div class="card">
              <p class="text-sm text-base-content/60">Avg Views</p>
              <p class="text-2xl font-semibold text-base-content tabular-nums mt-1">
                {format_number(@details.stats.avg_views_per_video)}
              </p>
            </div>
            <div class="card">
              <p class="text-sm text-base-content/60">Last Published</p>
              <p class="text-xl font-semibold text-base-content/70 tabular-nums mt-1">
                {format_date(@details.stats.last_publish_date)}
              </p>
            </div>
          </div>

          <div class="card">
            <h2 class="font-medium text-base-content mb-4">Sponsored Videos</h2>

            <%= if @details.videos == [] do %>
              <div class="py-8 text-center">
                <.icon name="hero-film" class="size-10 text-base-content/10 mx-auto mb-2" />
                <p class="text-sm text-base-content/50">No videos found</p>
              </div>
            <% else %>
              <.table id="sponsor-videos" rows={@details.videos}>
                <:col :let={video} label="Date">
                  <span class="text-sm tabular-nums">{format_date(video.published_at)}</span>
                </:col>
                <:col :let={video} label="Title">
                  <span class="truncate max-w-md block">{video.title}</span>
                </:col>
                <:col :let={video} label="Views">
                  <span class="tabular-nums">{format_number(video.view_count)}</span>
                </:col>
                <:action :let={video}>
                  <.button
                    navigate={~p"/videos/#{video.yt_video_id}"}
                    id={"sponsor-video-#{video.yt_video_id}"}
                  >
                    View
                  </.button>
                </:action>
              </.table>
            <% end %>
          </div>

          <div class="card">
            <h2 class="font-medium text-base-content mb-4">Sponsor Mentions</h2>

            <%= if @details.sponsor_mention_comments == [] do %>
              <div class="py-8 text-center">
                <.icon
                  name="hero-chat-bubble-left-right"
                  class="size-10 text-base-content/10 mx-auto mb-2"
                />
                <p class="text-sm text-base-content/50">No mentions found</p>
              </div>
            <% else %>
              <.table
                id="sponsor-mentions"
                rows={@details.sponsor_mention_comments}
                row_item={fn row -> row end}
              >
                <:col :let={row} label="Comment">
                  <span class="block max-w-md truncate">{row.comment.text}</span>
                </:col>
                <:col :let={row} label="Video">
                  <.link
                    navigate={~p"/videos/#{row.yt_video_id}"}
                    class="text-primary hover:underline text-sm truncate max-w-[150px] block"
                  >
                    {row.video_title}
                  </.link>
                </:col>
                <:col :let={row} label="Author">
                  <span class="text-sm">{row.comment.author}</span>
                </:col>
                <:col :let={row} label="Likes">
                  <span class="tabular-nums">{format_number(row.comment.like_count)}</span>
                </:col>
                <:action :let={row}>
                  <.button
                    href={youtube_comment_url(row.yt_video_id, row.comment.yt_comment_id)}
                    id={"open-sponsor-mention-#{row.comment.yt_comment_id}"}
                  >
                    Open
                  </.button>
                </:action>
              </.table>
            <% end %>
          </div>
        <% else %>
          <div class="card py-12 text-center">
            <.icon name="hero-arrow-path" class="size-8 text-primary mx-auto mb-2 animate-spin" />
            <p class="text-sm text-base-content/50">Loading sponsor data...</p>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  defp youtube_comment_url(yt_video_id, yt_comment_id) do
    "https://www.youtube.com/watch?v=#{yt_video_id}&lc=#{yt_comment_id}"
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

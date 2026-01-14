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
     |> assign(:details, nil)
     |> assign(:expanded_comments, MapSet.new())}
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
  def handle_event("toggle_comment", %{"comment-id" => comment_id}, socket) do
    expanded = socket.assigns.expanded_comments

    expanded =
      if MapSet.member?(expanded, comment_id) do
        MapSet.delete(expanded, comment_id)
      else
        MapSet.put(expanded, comment_id)
      end

    {:noreply, assign(socket, :expanded_comments, expanded)}
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
              <div class="overflow-x-auto">
                <table class="w-full text-sm">
                  <thead>
                    <tr class="border-b border-base-300">
                      <th class="text-left py-3 px-3 font-medium text-base-content/60">Comment</th>
                      <th class="text-left py-3 px-3 font-medium text-base-content/60">Video</th>
                      <th class="text-left py-3 px-3 font-medium text-base-content/60">Author</th>
                      <th class="text-left py-3 px-3 font-medium text-base-content/60">Likes</th>
                      <th class="py-3 px-3"><span class="sr-only">Actions</span></th>
                    </tr>
                  </thead>
                  <tbody id="sponsor-mentions">
                    <tr
                      :for={row <- @details.sponsor_mention_comments}
                      id={"sponsor-mention-#{row.comment.yt_comment_id}"}
                      class="border-b border-base-300/50 hover:bg-base-300/30"
                    >
                      <td class="py-3 px-3">
                        <.expandable_comment
                          text={row.comment.text}
                          comment_id={row.comment.yt_comment_id}
                          expanded={MapSet.member?(@expanded_comments, row.comment.yt_comment_id)}
                        />
                      </td>
                      <td class="py-3 px-3">
                        <.link
                          navigate={~p"/videos/#{row.yt_video_id}"}
                          class="text-primary hover:underline text-sm truncate max-w-[150px] block"
                        >
                          {row.video_title}
                        </.link>
                      </td>
                      <td class="py-3 px-3">
                        <span class="text-sm">{row.comment.author}</span>
                      </td>
                      <td class="py-3 px-3">
                        <span class="tabular-nums">{format_number(row.comment.like_count)}</span>
                      </td>
                      <td class="py-3 px-3">
                        <div class="flex items-center justify-end gap-2">
                          <.button
                            href={youtube_comment_url(row.yt_video_id, row.comment.yt_comment_id)}
                            id={"open-sponsor-mention-#{row.comment.yt_comment_id}"}
                          >
                            Open
                          </.button>
                        </div>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
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

  @max_comment_length 100

  attr :text, :string, required: true
  attr :comment_id, :string, required: true
  attr :expanded, :boolean, required: true

  defp expandable_comment(assigns) do
    truncated = String.length(assigns.text) > @max_comment_length

    assigns =
      assigns
      |> assign(:truncated, truncated)
      |> assign(:max_comment_length, @max_comment_length)

    ~H"""
    <%= if @truncated do %>
      <button
        phx-click="toggle_comment"
        phx-value-comment-id={@comment_id}
        class="text-left max-w-md cursor-pointer hover:bg-base-300/50 rounded px-1 -mx-1 transition-colors"
      >
        <%= if @expanded do %>
          <span class="block whitespace-pre-wrap">{@text}</span>
          <span class="text-xs text-primary mt-1 block">Click to collapse</span>
        <% else %>
          <span class="block truncate">{String.slice(@text, 0, @max_comment_length)}...</span>
          <span class="text-xs text-primary mt-1 block">Click to expand</span>
        <% end %>
      </button>
    <% else %>
      <span class="block max-w-md">{@text}</span>
    <% end %>
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

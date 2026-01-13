defmodule R8yV4Web.VideoLive.Show do
  @moduledoc """
  Video detail page with comments and notifications.
  """
  use R8yV4Web, :live_view

  alias R8yV4.Monitoring

  @comments_limit 200

  @impl true
  def mount(%{"yt_video_id" => yt_video_id}, _session, socket) do
    {:ok,
     socket
     |> assign(:yt_video_id, yt_video_id)
     |> assign(:page_title, "Video")
     |> assign(:video, nil)
     |> assign(:filter, "all")
     |> assign(:comments_limit, @comments_limit)
     |> assign(:notifications, [])
     |> stream_configure(:comments, dom_id: &("comments-" <> &1.yt_comment_id))
     |> stream(:comments, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    yt_video_id = socket.assigns.yt_video_id
    filter = Map.get(params, "filter", "all")

    video = Monitoring.get_video_with_relations!(yt_video_id)

    comments =
      Monitoring.list_comments_for_video(yt_video_id,
        filter: filter,
        limit: @comments_limit
      )

    notifications = Monitoring.list_notifications_for_video(yt_video_id, limit: 50)

    {:noreply,
     socket
     |> assign(:page_title, video.title)
     |> assign(:video, video)
     |> assign(:filter, filter)
     |> assign(:notifications, notifications)
     |> stream(:comments, comments, reset: true)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div id="video-show" class="space-y-6">
        <%= if @video do %>
          <div class="flex items-start justify-between gap-4">
            <div class="min-w-0">
              <h1 class="text-xl font-semibold text-base-content line-clamp-2">{@video.title}</h1>
              <div class="flex items-center gap-2 mt-2 text-sm text-base-content/50">
                <span>{@video.channel && @video.channel.name}</span>
                <span>·</span>
                <span class="tabular-nums">{format_date(@video.published_at)}</span>
                <span>·</span>
                <span class="font-mono text-xs">{@video.yt_video_id}</span>
              </div>
            </div>
            <div class="flex items-center gap-2 flex-shrink-0">
              <.button navigate={~p"/videos"} id="back-to-videos">
                <.icon name="hero-arrow-left" class="size-4" /> Back
              </.button>
              <.button
                href={youtube_video_url(@video.yt_video_id)}
                id="open-youtube"
                variant="primary"
              >
                YouTube
              </.button>
            </div>
          </div>

          <div class="card">
            <div class="flex flex-col md:flex-row gap-6">
              <a
                href={youtube_video_url(@video.yt_video_id)}
                target="_blank"
                rel="noopener noreferrer"
                class="flex-shrink-0"
              >
                <img
                  :if={@video.thumbnail_url}
                  src={@video.thumbnail_url}
                  alt=""
                  class="w-48 h-28 object-cover rounded"
                />
              </a>

              <div class="flex-1 min-w-0 space-y-4">
                <div class="flex flex-wrap items-center gap-2">
                  <span class="text-xs px-2 py-1 rounded bg-base-300 text-base-content/60">
                    {format_number(@video.view_count)} views
                  </span>
                  <span class="text-xs px-2 py-1 rounded bg-base-300 text-base-content/60">
                    {format_number(@video.like_count)} likes
                  </span>
                  <span class="text-xs px-2 py-1 rounded bg-base-300 text-base-content/60">
                    {format_number(@video.comment_count)} comments
                  </span>
                  <%= if sponsor = Enum.at(@video.sponsors || [], 0) do %>
                    <span class="text-xs px-2 py-1 rounded bg-success/20 text-success">
                      Sponsor: {sponsor.name}
                    </span>
                  <% end %>
                </div>

                <details class="bg-base-300/50 rounded-lg p-3">
                  <summary class="text-sm text-base-content/60 cursor-pointer">Description</summary>
                  <p class="mt-3 text-sm text-base-content/70 whitespace-pre-wrap leading-relaxed max-h-48 overflow-y-auto">
                    {@video.description}
                  </p>
                </details>
              </div>
            </div>
          </div>

          <div class="card">
            <div class="flex items-center justify-between mb-4">
              <div class="flex items-center gap-2">
                <h2 class="font-medium text-base-content">Comments</h2>
                <span class="text-xs text-base-content/40">(up to {@comments_limit})</span>
              </div>

              <div class="flex items-center gap-1">
                <.filter_tab
                  href={filter_patch_path(@video.yt_video_id, "all")}
                  active={@filter == "all"}
                  id="filter-all"
                >
                  All
                </.filter_tab>
                <.filter_tab
                  href={filter_patch_path(@video.yt_video_id, "flagged")}
                  active={@filter == "flagged"}
                  id="filter-flagged"
                >
                  Flagged
                </.filter_tab>
                <.filter_tab
                  href={filter_patch_path(@video.yt_video_id, "unprocessed")}
                  active={@filter == "unprocessed"}
                  id="filter-unprocessed"
                >
                  Unprocessed
                </.filter_tab>
              </div>
            </div>

            <div id="comments" phx-update="stream" class="space-y-3">
              <div
                id="comments-empty"
                class="hidden only:flex flex-col items-center justify-center py-8 text-center"
              >
                <.icon name="hero-chat-bubble-left-right" class="size-10 text-base-content/10 mb-2" />
                <p class="text-sm text-base-content/50">No comments found</p>
              </div>

              <div
                :for={{dom_id, comment} <- @streams.comments}
                id={dom_id}
                class={[
                  "p-4 rounded-lg border transition-colors",
                  flagged?(comment) && "border-warning/40 bg-warning/5",
                  !flagged?(comment) && !comment.is_processed && "border-info/40 bg-info/5",
                  !flagged?(comment) && comment.is_processed && "border-neutral bg-base-300/30"
                ]}
              >
                <div class="flex items-start justify-between gap-4">
                  <div class="min-w-0 flex-1">
                    <div class="flex items-center gap-3 text-sm">
                      <span class="font-medium text-base-content/70">{comment.author}</span>
                      <span class="text-base-content/40 tabular-nums">
                        {format_datetime(comment.published_at)}
                      </span>
                      <span class="text-base-content/40">
                        {format_number(comment.like_count)} likes
                      </span>
                    </div>
                    <p class="mt-2 text-sm text-base-content/60 whitespace-pre-wrap leading-relaxed">
                      {comment.text}
                    </p>
                    <div class="mt-3 flex flex-wrap items-center gap-2">
                      <span class={[
                        "text-xs px-2 py-0.5 rounded",
                        comment.is_processed && "bg-success/20 text-success",
                        !comment.is_processed && "bg-base-300 text-base-content/50"
                      ]}>
                        {if comment.is_processed, do: "Processed", else: "Pending"}
                      </span>
                      <span
                        :if={comment.is_editing_mistake}
                        class="text-xs px-2 py-0.5 rounded bg-warning/20 text-warning"
                      >
                        Editing mistake
                      </span>
                      <span
                        :if={comment.is_sponsor_mention}
                        class="text-xs px-2 py-0.5 rounded bg-info/20 text-info"
                      >
                        Sponsor mention
                      </span>
                      <span
                        :if={comment.is_question}
                        class="text-xs px-2 py-0.5 rounded bg-info/20 text-info"
                      >
                        Question
                      </span>
                      <span
                        :if={comment.is_positive_comment}
                        class="text-xs px-2 py-0.5 rounded bg-success/20 text-success"
                      >
                        Positive
                      </span>
                    </div>
                  </div>
                  <.button
                    href={youtube_comment_url(@video.yt_video_id, comment.yt_comment_id)}
                    id={"open-comment-#{comment.yt_comment_id}"}
                  >
                    Open
                  </.button>
                </div>
              </div>
            </div>
          </div>

          <div class="card">
            <div class="flex items-center gap-2 mb-4">
              <h2 class="font-medium text-base-content">Notifications</h2>
              <span class="text-xs text-base-content/40">(last 50)</span>
            </div>

            <div id="notifications" class="space-y-3">
              <div :if={@notifications == []} class="py-8 text-center">
                <.icon name="hero-bell" class="size-10 text-base-content/10 mx-auto mb-2" />
                <p class="text-sm text-base-content/50">No notifications logged</p>
              </div>

              <div
                :for={notification <- @notifications}
                id={"notification-#{notification.notification_id}"}
                class="p-4 rounded-lg bg-base-300/30 border border-neutral"
              >
                <div class="flex items-start justify-between gap-4">
                  <div class="min-w-0 flex-1">
                    <div class="flex items-center gap-3 text-sm">
                      <span class="font-medium text-base-content/70">
                        {format_notification_type(notification.type)}
                      </span>
                      <span class={[
                        "text-xs px-2 py-0.5 rounded",
                        notification.success && "bg-success/20 text-success",
                        !notification.success && "bg-error/20 text-error"
                      ]}>
                        {if notification.success, do: "OK", else: "Failed"}
                      </span>
                      <span class="text-base-content/40 tabular-nums">
                        {format_datetime(notification.created_at)}
                      </span>
                    </div>
                    <p class="mt-2 text-sm text-base-content/60">{notification.message}</p>
                  </div>
                  <%= if notification.comment_id do %>
                    <.button
                      href={youtube_comment_url(@video.yt_video_id, notification.comment_id)}
                      id={"notification-comment-#{notification.notification_id}"}
                    >
                      Comment
                    </.button>
                  <% end %>
                </div>
              </div>
            </div>
          </div>
        <% else %>
          <div class="card py-12 text-center">
            <.icon name="hero-arrow-path" class="size-8 text-primary mx-auto mb-2 animate-spin" />
            <p class="text-sm text-base-content/50">Loading video data...</p>
          </div>
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  attr :href, :string, required: true
  attr :active, :boolean, required: true
  attr :id, :string, required: true
  slot :inner_block, required: true

  defp filter_tab(assigns) do
    ~H"""
    <.link
      patch={@href}
      id={@id}
      class={[
        "px-3 py-1 text-xs rounded transition-colors",
        @active && "bg-primary text-primary-content",
        !@active && "text-base-content/50 hover:text-base-content/70 hover:bg-base-300"
      ]}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  defp filter_patch_path(yt_video_id, "all"), do: ~p"/videos/#{yt_video_id}"
  defp filter_patch_path(yt_video_id, filter), do: ~p"/videos/#{yt_video_id}?filter=#{filter}"

  defp youtube_video_url(yt_video_id), do: "https://www.youtube.com/watch?v=#{yt_video_id}"

  defp youtube_comment_url(yt_video_id, yt_comment_id) do
    "https://www.youtube.com/watch?v=#{yt_video_id}&lc=#{yt_comment_id}"
  end

  defp flagged?(comment) do
    comment.is_editing_mistake or comment.is_sponsor_mention or comment.is_question
  end

  defp format_notification_type(nil), do: "Unknown"

  defp format_notification_type(type) when is_atom(type) do
    type
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp format_date(nil), do: "—"
  defp format_date(%NaiveDateTime{} = naive), do: Calendar.strftime(naive, "%Y-%m-%d")

  defp format_datetime(nil), do: "—"
  defp format_datetime(%NaiveDateTime{} = naive), do: Calendar.strftime(naive, "%m-%d %H:%M")

  defp format_number(value) when is_integer(value) do
    value
    |> Integer.to_string()
    |> String.replace(~r/\B(?=(\d{3})+(?!\d))/, ",")
  end

  defp format_number(_), do: "0"
end

defmodule R8yV4Web.ChannelLive.Show do
  @moduledoc """
  Channel detail page with tabbed interface.
  """
  use R8yV4Web, :live_view

  alias R8yV4.Monitoring

  @impl true
  def mount(%{"yt_channel_id" => yt_channel_id}, _session, socket) do
    {:ok,
     socket
     |> assign(:yt_channel_id, yt_channel_id)
     |> assign(:page_title, "Channel")
     |> assign(:channel_stats, nil)
     |> assign(:videos, [])
     |> assign(:videos_count, 0)
     |> assign(:sponsors, [])
     |> assign(:sponsor_mentions, [])
     |> assign(:notifications, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    yt_channel_id = socket.assigns.yt_channel_id

    tab = Map.get(params, "tab", "overview")

    channel_stats = Monitoring.get_channel_with_recent_stats(yt_channel_id)

    videos = Monitoring.list_channel_videos(yt_channel_id, limit: 50)
    videos_count = Monitoring.count_channel_videos(yt_channel_id)

    sponsors = Monitoring.list_channel_sponsors_with_stats(yt_channel_id)
    sponsor_mentions = Monitoring.list_channel_sponsor_mentions(yt_channel_id, limit: 40)
    notifications = Monitoring.list_notifications_for_channel(yt_channel_id, limit: 50)

    {:noreply,
     socket
     |> assign(:page_title, channel_stats.channel.name)
     |> assign(:tab, tab)
     |> assign(:channel_stats, channel_stats)
     |> assign(:videos, videos)
     |> assign(:videos_count, videos_count)
     |> assign(:sponsors, sponsors)
     |> assign(:sponsor_mentions, sponsor_mentions)
     |> assign(:notifications, notifications)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div id="channel-show" class="space-y-6">
        <div class="flex items-start justify-between gap-4">
          <div class="min-w-0">
            <h1 class="text-2xl font-semibold text-base-content truncate">{@page_title}</h1>
            <p class="text-xs text-base-content/40 mt-1 font-mono truncate">{@yt_channel_id}</p>
          </div>
          <div class="flex items-center gap-2 flex-shrink-0">
            <.button navigate={~p"/channels"} id="back-to-channels">
              <.icon name="hero-arrow-left" class="size-4" /> Back
            </.button>
            <.button
              navigate={~p"/channels/#{@yt_channel_id}/edit"}
              id="edit-channel"
              variant="primary"
            >
              Edit
            </.button>
          </div>
        </div>

        <%= if @channel_stats do %>
          <div class="grid grid-cols-3 gap-4">
            <div class="card">
              <p class="text-sm text-base-content/60">Total Videos</p>
              <p class="text-2xl font-semibold text-base-content tabular-nums mt-1">
                {format_number(@videos_count)}
              </p>
            </div>
            <div class="card">
              <p class="text-sm text-base-content/60">Videos (30d)</p>
              <p class="text-2xl font-semibold text-base-content tabular-nums mt-1">
                {format_number(@channel_stats.video_count)}
              </p>
            </div>
            <div class="card">
              <p class="text-sm text-base-content/60">Views (30d)</p>
              <p class="text-2xl font-semibold text-base-content tabular-nums mt-1">
                {format_number(@channel_stats.total_views)}
              </p>
            </div>
          </div>
        <% end %>

        <div class="flex items-center gap-1 border-b border-neutral" id="channel-tabs">
          <.tab_link
            href={tab_patch_path(@yt_channel_id, "overview")}
            active={@tab == "overview"}
            id="tab-overview"
          >
            Overview
          </.tab_link>
          <.tab_link
            href={tab_patch_path(@yt_channel_id, "sponsors")}
            active={@tab == "sponsors"}
            id="tab-sponsors"
          >
            Sponsors
          </.tab_link>
          <.tab_link
            href={tab_patch_path(@yt_channel_id, "mentions")}
            active={@tab == "mentions"}
            id="tab-mentions"
          >
            Mentions
          </.tab_link>
          <.tab_link
            href={tab_patch_path(@yt_channel_id, "notifications")}
            active={@tab == "notifications"}
            id="tab-notifications"
          >
            Notifications
          </.tab_link>
        </div>

        <%= case @tab do %>
          <% "sponsors" -> %>
            {render_sponsors(assigns)}
          <% "mentions" -> %>
            {render_mentions(assigns)}
          <% "notifications" -> %>
            {render_notifications(assigns)}
          <% _ -> %>
            {render_overview(assigns)}
        <% end %>
      </div>
    </Layouts.app>
    """
  end

  attr :href, :string, required: true
  attr :active, :boolean, required: true
  attr :id, :string, required: true
  slot :inner_block, required: true

  defp tab_link(assigns) do
    ~H"""
    <.link
      patch={@href}
      id={@id}
      class={[
        "px-4 py-2 text-sm transition-colors border-b-2 -mb-px",
        @active && "text-primary border-primary",
        !@active && "text-base-content/50 border-transparent hover:text-base-content/70"
      ]}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  defp render_overview(assigns) do
    ~H"""
    <div class="card">
      <div class="flex items-center justify-between mb-4">
        <h2 class="font-medium text-base-content">Recent Videos</h2>
        <span class="text-xs text-base-content/40">Showing latest 50</span>
      </div>

      <%= if @videos == [] do %>
        <div class="text-center py-8">
          <.icon name="hero-film" class="size-10 text-base-content/10 mx-auto mb-2" />
          <p class="text-sm text-base-content/50">No videos synced yet</p>
        </div>
      <% else %>
        <.table id="channel-videos" rows={@videos}>
          <:col :let={video} label="Date">
            <span class="text-sm tabular-nums">{format_date(video.published_at)}</span>
          </:col>
          <:col :let={video} label="Title">
            <span class="truncate max-w-md block">{video.title}</span>
          </:col>
          <:col :let={video} label="Views">
            <span class="text-sm tabular-nums">{format_number(video.view_count)}</span>
          </:col>
          <:col :let={video} label="Sponsor">
            <span class={["text-sm", video_sponsor_label(video) != "—" && "text-success"]}>
              {video_sponsor_label(video)}
            </span>
          </:col>
          <:action :let={video}>
            <.button navigate={~p"/videos/#{video.yt_video_id}"} id={"video-#{video.yt_video_id}"}>
              View
            </.button>
          </:action>
        </.table>
      <% end %>
    </div>
    """
  end

  defp render_sponsors(assigns) do
    ~H"""
    <div class="card">
      <h2 class="font-medium text-base-content mb-4">Detected Sponsors</h2>

      <%= if @sponsors == [] do %>
        <div class="text-center py-8">
          <.icon name="hero-currency-dollar" class="size-10 text-base-content/10 mx-auto mb-2" />
          <p class="text-sm text-base-content/50">No sponsors detected</p>
        </div>
      <% else %>
        <.table id="channel-sponsors" rows={@sponsors} row_item={fn row -> row end}>
          <:col :let={row} label="Sponsor">
            <.link
              navigate={~p"/sponsors/#{row.sponsor.sponsor_id}"}
              id={"sponsor-#{row.sponsor.sponsor_id}"}
              class="text-primary hover:underline font-medium"
            >
              {row.sponsor.name}
            </.link>
          </:col>
          <:col :let={row} label="Ads">
            <span class="tabular-nums">{format_number(row.total_videos)}</span>
          </:col>
          <:col :let={row} label="Views">
            <span class="tabular-nums">{format_number(row.total_views)}</span>
          </:col>
          <:col :let={row} label="Avg">
            <span class="tabular-nums">{format_number(row.avg_views_per_video)}</span>
          </:col>
          <:col :let={row} label="Last">
            <span class="text-sm tabular-nums">{format_date(row.last_video_published_at)}</span>
          </:col>
        </.table>
      <% end %>
    </div>
    """
  end

  defp render_mentions(assigns) do
    ~H"""
    <div class="card">
      <div class="flex items-center justify-between mb-4">
        <h2 class="font-medium text-base-content">Sponsor Mentions</h2>
        <span class="text-xs text-base-content/40">Latest 40 comments</span>
      </div>

      <%= if @sponsor_mentions == [] do %>
        <div class="text-center py-8">
          <.icon name="hero-chat-bubble-left-right" class="size-10 text-base-content/10 mx-auto mb-2" />
          <p class="text-sm text-base-content/50">No sponsor mentions found</p>
        </div>
      <% else %>
        <.table id="channel-mentions" rows={@sponsor_mentions} row_item={fn row -> row end}>
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
              id={"open-mention-#{row.comment.yt_comment_id}"}
            >
              Open
            </.button>
          </:action>
        </.table>
      <% end %>
    </div>
    """
  end

  defp render_notifications(assigns) do
    ~H"""
    <div class="card">
      <div class="flex items-center justify-between mb-4">
        <h2 class="font-medium text-base-content">Notification Log</h2>
        <span class="text-xs text-base-content/40">Last 50 entries</span>
      </div>

      <%= if @notifications == [] do %>
        <div class="text-center py-8">
          <.icon name="hero-bell" class="size-10 text-base-content/10 mx-auto mb-2" />
          <p class="text-sm text-base-content/50">No notifications logged</p>
        </div>
      <% else %>
        <.table id="channel-notifications" rows={@notifications} row_item={fn row -> row end}>
          <:col :let={row} label="Type">
            <span class="text-sm">{format_notification_type(row.notification.type)}</span>
          </:col>
          <:col :let={row} label="Status">
            <span class={[
              "text-xs px-2 py-0.5 rounded",
              row.notification.success && "bg-success/20 text-success",
              !row.notification.success && "bg-error/20 text-error"
            ]}>
              {if row.notification.success, do: "OK", else: "FAIL"}
            </span>
          </:col>
          <:col :let={row} label="Message">
            <span class="block max-w-md truncate">{row.notification.message}</span>
          </:col>
          <:col :let={row} label="Video">
            <.link
              navigate={~p"/videos/#{row.yt_video_id}"}
              class="text-primary hover:underline text-sm truncate max-w-[100px] block"
            >
              {row.video_title}
            </.link>
          </:col>
          <:col :let={row} label="Time">
            <span class="text-sm tabular-nums">{format_datetime(row.notification.created_at)}</span>
          </:col>
        </.table>
      <% end %>
    </div>
    """
  end

  defp tab_patch_path(yt_channel_id, "overview"), do: ~p"/channels/#{yt_channel_id}"
  defp tab_patch_path(yt_channel_id, tab), do: ~p"/channels/#{yt_channel_id}?tab=#{tab}"

  defp youtube_comment_url(yt_video_id, yt_comment_id) do
    "https://www.youtube.com/watch?v=#{yt_video_id}&lc=#{yt_comment_id}"
  end

  defp video_sponsor_label(video) do
    case Enum.at(video.sponsors || [], 0) do
      nil -> "—"
      sponsor -> sponsor.name
    end
  end

  defp format_notification_type(nil), do: "unknown"

  defp format_notification_type(type) when is_atom(type) do
    type
    |> Atom.to_string()
    |> String.replace("_", " ")
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

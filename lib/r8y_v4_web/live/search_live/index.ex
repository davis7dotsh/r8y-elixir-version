defmodule R8yV4Web.SearchLive.Index do
  @moduledoc """
  Global search interface.
  """
  use R8yV4Web, :live_view

  alias R8yV4.Monitoring

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:page_title, "Search")
      |> assign(:query, "")
      |> assign(:yt_channel_id, "")
      |> assign(:results, %{channels: [], sponsors: [], videos: []})
      |> assign(:form, to_form(%{"query" => "", "yt_channel_id" => ""}, as: :search))

    {:ok, socket}
  end

  @impl true
  def handle_event("change", %{"search" => params}, socket) do
    query = Map.get(params, "query", "")
    yt_channel_id = Map.get(params, "yt_channel_id", "")

    results =
      Monitoring.search(query,
        yt_channel_id: yt_channel_id,
        limit: 4
      )

    socket =
      socket
      |> assign(:query, query)
      |> assign(:yt_channel_id, yt_channel_id)
      |> assign(:results, results)
      |> assign(:form, to_form(params, as: :search))

    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div id="search" class="space-y-6">
        <div>
          <h1 class="text-2xl font-semibold text-base-content">Search</h1>
          <p class="text-sm text-base-content/60 mt-1">
            Query channels, videos, and sponsors
          </p>
        </div>

        <div class="card">
          <.form for={@form} id="search-form" phx-change="change" class="space-y-4">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <.input
                field={@form[:query]}
                type="text"
                label="Search"
                placeholder="video title, sponsor, channel..."
              />
              <.input
                field={@form[:yt_channel_id]}
                type="text"
                label="Channel Filter (optional)"
                placeholder="UC..."
              />
            </div>
          </.form>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div class="card">
            <h2 class="font-medium text-base-content mb-4">Channels</h2>

            <div id="search-channels" class="space-y-2">
              <.empty_state :if={@results.channels == [] and String.trim(@query) == ""}>
                Enter a search term
              </.empty_state>
              <.empty_state :if={@results.channels == [] and String.trim(@query) != ""}>
                No channels found
              </.empty_state>

              <.link
                :for={channel <- @results.channels}
                navigate={~p"/channels/#{channel.yt_channel_id}"}
                id={"search-channel-#{channel.yt_channel_id}"}
                class="block p-3 rounded-lg bg-base-300/30 border border-neutral hover:border-primary/30 transition-colors"
              >
                <p class="text-base-content/80 hover:text-primary truncate">{channel.name}</p>
                <p class="text-xs text-base-content/40 mt-1 font-mono truncate">
                  {channel.yt_channel_id}
                </p>
              </.link>
            </div>
          </div>

          <div class="card">
            <h2 class="font-medium text-base-content mb-4">Sponsors</h2>

            <div id="search-sponsors" class="space-y-2">
              <.empty_state :if={@results.sponsors == [] and String.trim(@query) == ""}>
                Enter a search term
              </.empty_state>
              <.empty_state :if={@results.sponsors == [] and String.trim(@query) != ""}>
                No sponsors found
              </.empty_state>

              <.link
                :for={sponsor <- @results.sponsors}
                navigate={~p"/sponsors/#{sponsor.sponsor_id}"}
                id={"search-sponsor-#{sponsor.sponsor_id}"}
                class="block p-3 rounded-lg bg-base-300/30 border border-neutral hover:border-success/30 transition-colors"
              >
                <p class="text-base-content/80 hover:text-success truncate">{sponsor.name}</p>
                <p class="text-xs text-base-content/40 mt-1 truncate">{sponsor.sponsor_key}</p>
              </.link>
            </div>
          </div>

          <div class="card">
            <h2 class="font-medium text-base-content mb-4">Videos</h2>

            <div id="search-videos" class="space-y-2">
              <.empty_state :if={@results.videos == [] and String.trim(@query) == ""}>
                Enter a search term
              </.empty_state>
              <.empty_state :if={@results.videos == [] and String.trim(@query) != ""}>
                No videos found
              </.empty_state>

              <.link
                :for={video <- @results.videos}
                navigate={~p"/videos/#{video.yt_video_id}"}
                id={"search-video-#{video.yt_video_id}"}
                class="block p-3 rounded-lg bg-base-300/30 border border-neutral hover:border-warning/30 transition-colors"
              >
                <p class="text-base-content/80 hover:text-warning truncate">{video.title}</p>
                <p class="text-xs text-base-content/40 mt-1 font-mono truncate">
                  {video.yt_video_id}
                </p>
              </.link>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  slot :inner_block, required: true

  defp empty_state(assigns) do
    ~H"""
    <div class="py-6 text-center">
      <p class="text-sm text-base-content/40">{render_slot(@inner_block)}</p>
    </div>
    """
  end
end

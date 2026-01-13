defmodule R8yV4Web.ChannelLive.Index do
  @moduledoc """
  Channel listing page.
  """
  use R8yV4Web, :live_view

  alias R8yV4.Monitoring

  @impl true
  def mount(_params, _session, socket) do
    channels = Monitoring.list_channels()

    socket =
      socket
      |> assign(:page_title, "Channels")
      |> stream_configure(:channels, dom_id: &("channels-" <> &1.yt_channel_id))

    {:ok, stream(socket, :channels, channels)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-6">
        <div class="flex items-start justify-between gap-4">
          <div>
            <h1 class="text-2xl font-semibold text-base-content">Channels</h1>
            <p class="text-sm text-base-content/60 mt-1">
              Monitored YouTube channels
            </p>
          </div>
          <.button navigate={~p"/channels/new"} id="new-channel" variant="primary">
            <.icon name="hero-plus" class="size-4" /> Add Channel
          </.button>
        </div>

        <div class="card">
          <div id="channels" phx-update="stream" class="divide-y divide-neutral">
            <div
              id="channels-empty"
              class="hidden only:flex flex-col items-center justify-center py-12 text-center"
            >
              <.icon name="hero-tv" class="size-12 text-base-content/10 mb-4" />
              <p class="text-base-content/50 mb-2">No channels configured</p>
              <.link navigate={~p"/channels/new"} class="text-sm text-primary hover:underline">
                Add your first channel
              </.link>
            </div>

            <div
              :for={{dom_id, channel} <- @streams.channels}
              id={dom_id}
              class="py-4 first:pt-0 last:pb-0"
            >
              <div class="flex items-center justify-between gap-4">
                <div class="min-w-0 flex-1">
                  <.link
                    navigate={~p"/channels/#{channel.yt_channel_id}"}
                    class="font-medium text-base-content hover:text-primary transition-colors"
                  >
                    {channel.name}
                  </.link>
                  <p class="text-xs text-base-content/40 mt-1 font-mono truncate">
                    {channel.yt_channel_id}
                  </p>
                </div>

                <div class="flex items-center gap-2">
                  <.button
                    navigate={~p"/channels/#{channel.yt_channel_id}"}
                    id={"view-#{channel.yt_channel_id}"}
                    variant="primary"
                  >
                    View
                  </.button>
                  <.button
                    patch={~p"/channels/#{channel.yt_channel_id}/edit"}
                    id={"edit-#{channel.yt_channel_id}"}
                  >
                    Edit
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
end

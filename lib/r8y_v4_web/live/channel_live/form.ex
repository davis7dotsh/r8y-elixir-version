defmodule R8yV4Web.ChannelLive.Form do
  @moduledoc """
  Channel form for creating and editing channels.
  """
  use R8yV4Web, :live_view

  alias R8yV4.Monitoring
  alias R8yV4.Monitoring.Channel

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("validate", %{"channel" => channel_params}, socket) do
    changeset =
      socket.assigns.channel
      |> Monitoring.change_channel(channel_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"channel" => channel_params}, socket) do
    save_channel(socket, socket.assigns.live_action, channel_params)
  end

  defp apply_action(socket, :new, _params) do
    channel = %Channel{}

    socket
    |> assign(:page_title, "New Channel")
    |> assign(:channel, channel)
    |> assign_form(Monitoring.change_channel(channel))
  end

  defp apply_action(socket, :edit, %{"yt_channel_id" => yt_channel_id}) do
    channel = Monitoring.get_channel!(yt_channel_id)

    socket
    |> assign(:page_title, "Edit Channel")
    |> assign(:channel, channel)
    |> assign_form(Monitoring.change_channel(channel))
  end

  defp save_channel(socket, :new, channel_params) do
    case Monitoring.create_channel(channel_params) do
      {:ok, _channel} ->
        {:noreply,
         socket
         |> put_flash(:info, "Channel created successfully.")
         |> push_navigate(to: ~p"/channels")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_channel(socket, :edit, channel_params) do
    channel = socket.assigns.channel

    case Monitoring.update_channel(channel, channel_params) do
      {:ok, _channel} ->
        {:noreply,
         socket
         |> put_flash(:info, "Channel updated successfully.")
         |> push_navigate(to: ~p"/channels")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-2xl space-y-6">
        <div class="flex items-start justify-between gap-4">
          <div>
            <h1 class="text-2xl font-semibold text-base-content">
              {if @live_action == :new, do: "Add Channel", else: "Edit Channel"}
            </h1>
            <p class="text-sm text-base-content/60 mt-1">
              {if @live_action == :new,
                do: "Register a new YouTube channel for monitoring",
                else: "Update channel configuration"}
            </p>
          </div>
          <.button navigate={~p"/channels"} id="back-to-channels">
            <.icon name="hero-arrow-left" class="size-4" /> Back
          </.button>
        </div>

        <div class="card">
          <.form
            for={@form}
            id="channel-form"
            phx-change="validate"
            phx-submit="save"
            class="space-y-6"
          >
            <div>
              <.input
                field={@form[:yt_channel_id]}
                type="text"
                label="YouTube Channel ID"
                placeholder="UC..."
                disabled={@live_action == :edit}
              />
              <p class="text-xs text-base-content/40 mt-1">
                The unique channel identifier (not the @handle)
              </p>
            </div>

            <.input
              field={@form[:name]}
              type="text"
              label="Display Name"
              placeholder="Channel name for display"
            />

            <div>
              <.input
                field={@form[:find_sponsor_prompt]}
                type="textarea"
                label="Sponsor Detection Prompt"
                placeholder="Custom prompt for sponsor detection AI..."
              />
              <p class="text-xs text-base-content/40 mt-1">
                Optional: Custom instructions for the sponsor detection system
              </p>
            </div>

            <div class="flex items-center justify-end gap-3 pt-4 border-t border-neutral">
              <.button navigate={~p"/channels"} id="cancel-channel">
                Cancel
              </.button>
              <.button type="submit" id="save-channel" variant="primary">
                {if @live_action == :new, do: "Create Channel", else: "Save Changes"}
              </.button>
            </div>
          </.form>
        </div>
      </div>
    </Layouts.app>
    """
  end
end

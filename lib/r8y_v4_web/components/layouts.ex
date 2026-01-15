defmodule R8yV4Web.Layouts do
  @moduledoc """
  Application layouts.
  """
  use R8yV4Web, :html

  embed_templates("layouts/*")

  @doc """
  Renders the main app layout with navigation.
  """
  attr(:flash, :map, required: true, doc: "the map of flash messages")

  attr(:current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"
  )

  slot(:inner_block, required: true)

  def app(assigns) do
    ~H"""
    <div class="h-screen flex flex-col bg-base-200">
      <header class="flex-shrink-0 z-40 bg-base-200 border-b border-neutral">
        <div class="max-w-6xl mx-auto px-4 sm:px-6">
          <div class="flex items-center justify-between h-14">
            <a href="/" class="flex items-center gap-2">
              <span class="text-lg font-semibold text-primary">R8Y</span>
            </a>

            <nav class="flex items-center gap-1">
              <.nav_link href={~p"/channels"} icon="hero-tv">Channels</.nav_link>
              <.nav_link href={~p"/videos"} icon="hero-play">Videos</.nav_link>
              <.nav_link href={~p"/sponsors"} icon="hero-currency-dollar">Sponsors</.nav_link>
              <.nav_link href={~p"/search"} icon="hero-magnifying-glass">Search</.nav_link>
            </nav>
          </div>
        </div>
      </header>

      <main class="flex-1 overflow-y-auto">
        <div class="max-w-6xl mx-auto px-4 sm:px-6 py-6 pb-12">
          {render_slot(@inner_block)}
        </div>
      </main>

      <.flash_group flash={@flash} />
    </div>
    """
  end

  attr :href, :string, required: true
  attr :icon, :string, required: true
  slot :inner_block, required: true

  defp nav_link(assigns) do
    ~H"""
    <.link
      navigate={@href}
      class="flex items-center gap-2 px-3 py-2 text-sm text-base-content/70 hover:text-primary rounded-lg hover:bg-base-300 transition-colors"
    >
      <.icon name={@icon} class="size-4" />
      <span class="hidden sm:inline">{render_slot(@inner_block)}</span>
    </.link>
    """
  end

  @doc """
  Shows the flash group.
  """
  attr(:flash, :map, required: true, doc: "the map of flash messages")
  attr(:id, :string, default: "flash-group", doc: "the optional id of flash container")

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("Connection Lost")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Reconnecting to server")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Server Error")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end
end

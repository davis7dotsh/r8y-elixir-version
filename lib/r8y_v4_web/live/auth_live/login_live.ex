defmodule R8yV4Web.AuthLive.LoginLive do
  use R8yV4Web, :live_view

  alias R8yV4Web.Auth

  @impl true
  def mount(_params, _session, socket) do
    form = to_form(%{"password" => ""}, as: :login)
    {:ok, assign(socket, form: form, error: nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-base-100">
      <div class="w-full max-w-md px-8 py-10 bg-base-200 rounded-xl shadow-lg border border-neutral">
        <div class="text-center mb-8">
          <h1 class="text-2xl font-bold text-primary">R8Y</h1>
          <p class="text-base-content/60 mt-2">Enter password to continue</p>
        </div>

        <.form for={@form} id="login-form" phx-submit="login" class="space-y-6">
          <div>
            <.input
              field={@form[:password]}
              type="password"
              label="Password"
              placeholder="Enter password"
              autocomplete="current-password"
              autofocus
              required
            />
          </div>

          <p :if={@error} class="text-error text-sm">{@error}</p>

          <div>
            <.button type="submit" class="w-full">
              Log in
            </.button>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("login", %{"login" => %{"password" => password}}, socket) do
    if Auth.valid_password?(password) do
      {:noreply,
       socket
       |> push_navigate(to: ~p"/auth/callback?password=#{password}")}
    else
      {:noreply, assign(socket, error: "Invalid password")}
    end
  end
end

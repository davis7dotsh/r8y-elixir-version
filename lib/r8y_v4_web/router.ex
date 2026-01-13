defmodule R8yV4Web.Router do
  use R8yV4Web, :router

  import R8yV4Web.Auth

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {R8yV4Web.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  # Public routes - login page
  scope "/", R8yV4Web do
    pipe_through([:browser, :redirect_if_authenticated])

    live("/login", AuthLive.LoginLive, :login)
  end

  # Auth callbacks (controller routes for session handling)
  scope "/auth", R8yV4Web do
    pipe_through(:browser)

    get("/callback", AuthController, :callback)
    delete("/logout", AuthController, :logout)
    get("/logout", AuthController, :logout)
  end

  # Protected routes - require authentication
  scope "/", R8yV4Web do
    pipe_through([:browser, :require_auth])

    live("/", HomeLive, :index)

    live("/channels", ChannelLive.Index, :index)
    live("/channels/new", ChannelLive.Form, :new)
    live("/channels/:yt_channel_id", ChannelLive.Show, :show)
    live("/channels/:yt_channel_id/edit", ChannelLive.Form, :edit)

    live("/search", SearchLive.Index, :index)

    live("/videos", VideoLive.Index, :index)
    live("/videos/:yt_video_id", VideoLive.Show, :show)

    live("/sponsors", SponsorLive.Index, :index)
    live("/sponsors/:sponsor_id", SponsorLive.Show, :show)
  end

  # Other scopes may use custom stacks.
  # scope "/api", R8yV4Web do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:r8y_v4, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: R8yV4Web.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end
end

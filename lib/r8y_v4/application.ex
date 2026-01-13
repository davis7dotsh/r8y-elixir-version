defmodule R8yV4.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      R8yV4Web.Telemetry,
      R8yV4.Repo,
      {Oban, Application.fetch_env!(:r8y_v4, Oban)},
      {DNSCluster, query: Application.get_env(:r8y_v4, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: R8yV4.PubSub},
      # Start a worker by calling: R8yV4.Worker.start_link(arg)
      # {R8yV4.Worker, arg},
      # Start to serve requests, typically the last entry
      R8yV4Web.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: R8yV4.Supervisor]
    result = Supervisor.start_link(children, opts)

    # Trigger initial channel sync in dev
    if Application.get_env(:r8y_v4, :dev_routes) do
      Task.start(fn -> Oban.insert(R8yV4.Workers.ChannelSync.new(%{})) end)
    end

    result
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    R8yV4Web.Endpoint.config_change(changed, removed)
    :ok
  end
end

import Config

# Configure your database
#
# `DATABASE_URL_TEST` is preferred (when set), otherwise we fall back to
# `DATABASE_URL`, and finally to the default local test database config.
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
database_url = System.get_env("DATABASE_URL_TEST") || System.get_env("DATABASE_URL")

if database_url do
  config :r8y_v4, R8yV4.Repo,
    url: database_url,
    pool: Ecto.Adapters.SQL.Sandbox,
    pool_size: System.schedulers_online() * 2
else
  config :r8y_v4, R8yV4.Repo,
    username: "postgres",
    password: "postgres",
    hostname: "localhost",
    database: "r8y_v4_test#{System.get_env("MIX_TEST_PARTITION")}",
    pool: Ecto.Adapters.SQL.Sandbox,
    pool_size: System.schedulers_online() * 2
end

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :r8y_v4, R8yV4Web.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "pd3W/5ghR7ijfHOKPO3Ocnf+6wKmFqmgBGuD1eYvkOLXzc1jLT5VrL7G13I2UmxS",
  server: false

# In test we don't send emails
config :r8y_v4, R8yV4.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true

# In test we disable running queues/plugins and use manual job control.
config :r8y_v4, Oban,
  testing: :manual,
  plugins: false,
  queues: false

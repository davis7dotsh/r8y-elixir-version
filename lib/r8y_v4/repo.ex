defmodule R8yV4.Repo do
  use Ecto.Repo,
    otp_app: :r8y_v4,
    adapter: Ecto.Adapters.Postgres
end

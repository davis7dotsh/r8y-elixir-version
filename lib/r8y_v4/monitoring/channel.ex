defmodule R8yV4.Monitoring.Channel do
  use Ecto.Schema

  import Ecto.Changeset

  alias R8yV4.Monitoring.{Sponsor, Video}

  @primary_key {:yt_channel_id, :string, autogenerate: false}
  @derive {Phoenix.Param, key: :yt_channel_id}
  schema "channels" do
    field(:name, :string)
    field(:find_sponsor_prompt, :string)
    field(:created_at, :naive_datetime, read_after_writes: true)

    has_many(:videos, Video, foreign_key: :yt_channel_id)
    has_many(:sponsors, Sponsor, foreign_key: :yt_channel_id)
  end

  def changeset(channel, attrs) do
    channel
    |> cast(attrs, [:yt_channel_id, :name, :find_sponsor_prompt])
    |> validate_required([:yt_channel_id, :name, :find_sponsor_prompt])
    |> validate_length(:yt_channel_id, max: 55)
    |> validate_length(:name, min: 1)
  end
end

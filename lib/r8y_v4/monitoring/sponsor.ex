defmodule R8yV4.Monitoring.Sponsor do
  use Ecto.Schema

  import Ecto.Changeset

  alias R8yV4.Monitoring.{Channel, SponsorToVideo, Video}

  @primary_key {:sponsor_id, :string, autogenerate: false}
  @derive {Phoenix.Param, key: :sponsor_id}
  schema "sponsors" do
    belongs_to(:channel, Channel,
      references: :yt_channel_id,
      foreign_key: :yt_channel_id,
      type: :string
    )

    field(:sponsor_key, :string)
    field(:name, :string)
    field(:created_at, :naive_datetime, read_after_writes: true)

    many_to_many(:videos, Video,
      join_through: SponsorToVideo,
      join_keys: [sponsor_id: :sponsor_id, yt_video_id: :yt_video_id]
    )
  end

  def changeset(sponsor, attrs) do
    sponsor
    |> cast(attrs, [:sponsor_id, :yt_channel_id, :sponsor_key, :name])
    |> validate_required([:sponsor_id, :yt_channel_id, :sponsor_key, :name])
    |> validate_length(:sponsor_id, max: 55)
    |> validate_length(:yt_channel_id, max: 55)
    |> validate_length(:sponsor_key, min: 1, max: 255)
    |> validate_length(:name, min: 1, max: 255)
  end
end

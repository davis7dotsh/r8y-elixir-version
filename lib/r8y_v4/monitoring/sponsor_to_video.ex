defmodule R8yV4.Monitoring.SponsorToVideo do
  use Ecto.Schema

  import Ecto.Changeset

  alias R8yV4.Monitoring.{Sponsor, Video}

  @primary_key false
  schema "sponsor_to_videos" do
    belongs_to(:sponsor, Sponsor,
      references: :sponsor_id,
      foreign_key: :sponsor_id,
      type: :string,
      primary_key: true
    )

    belongs_to(:video, Video,
      references: :yt_video_id,
      foreign_key: :yt_video_id,
      type: :string,
      primary_key: true
    )

    field(:created_at, :naive_datetime, read_after_writes: true)
  end

  def changeset(sponsor_to_video, attrs) do
    sponsor_to_video
    |> cast(attrs, [:sponsor_id, :yt_video_id])
    |> validate_required([:sponsor_id, :yt_video_id])
    |> validate_length(:sponsor_id, max: 55)
    |> validate_length(:yt_video_id, max: 55)
  end
end

defmodule R8yV4.Monitoring.Video do
  use Ecto.Schema

  import Ecto.Changeset

  alias R8yV4.Monitoring.{Channel, Comment, Sponsor, SponsorToVideo}

  @primary_key {:yt_video_id, :string, autogenerate: false}
  @derive {Phoenix.Param, key: :yt_video_id}
  schema "videos" do
    belongs_to(:channel, Channel,
      references: :yt_channel_id,
      foreign_key: :yt_channel_id,
      type: :string
    )

    field(:title, :string)
    field(:description, :string)
    field(:thumbnail_url, :string)
    field(:published_at, :naive_datetime)
    field(:view_count, :integer, default: 0)
    field(:like_count, :integer, default: 0)
    field(:comment_count, :integer, default: 0)
    field(:created_at, :naive_datetime, read_after_writes: true)

    has_many(:comments, Comment, foreign_key: :yt_video_id)

    many_to_many(:sponsors, Sponsor,
      join_through: SponsorToVideo,
      join_keys: [yt_video_id: :yt_video_id, sponsor_id: :sponsor_id]
    )
  end

  def changeset(video, attrs) do
    video
    |> cast(attrs, [
      :yt_video_id,
      :yt_channel_id,
      :title,
      :description,
      :thumbnail_url,
      :published_at,
      :view_count,
      :like_count,
      :comment_count
    ])
    |> validate_required([
      :yt_video_id,
      :yt_channel_id,
      :title,
      :description,
      :thumbnail_url,
      :published_at,
      :view_count,
      :like_count,
      :comment_count
    ])
    |> validate_length(:yt_video_id, max: 55)
    |> validate_length(:yt_channel_id, max: 55)
    |> validate_length(:title, min: 1, max: 255)
  end

  def counts_changeset(video, attrs) do
    video
    |> cast(attrs, [:view_count, :like_count, :comment_count])
    |> validate_required([:view_count, :like_count, :comment_count])
  end
end

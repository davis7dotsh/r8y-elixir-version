defmodule R8yV4.Monitoring.Comment do
  use Ecto.Schema

  import Ecto.Changeset

  alias R8yV4.Monitoring.{Notification, Video}

  @primary_key {:yt_comment_id, :string, autogenerate: false}
  @derive {Phoenix.Param, key: :yt_comment_id}
  schema "comments" do
    belongs_to(:video, Video,
      references: :yt_video_id,
      foreign_key: :yt_video_id,
      type: :string
    )

    field(:text, :string)
    field(:author, :string)
    field(:published_at, :naive_datetime)
    field(:like_count, :integer, default: 0)
    field(:reply_count, :integer, default: 0)

    field(:is_editing_mistake, :boolean, default: false)
    field(:is_sponsor_mention, :boolean, default: false)
    field(:is_question, :boolean, default: false)
    field(:is_positive_comment, :boolean, default: false)
    field(:is_processed, :boolean, default: false)

    field(:created_at, :naive_datetime, read_after_writes: true)

    has_many(:notifications, Notification, foreign_key: :comment_id)
  end

  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [
      :yt_comment_id,
      :yt_video_id,
      :text,
      :author,
      :published_at,
      :like_count,
      :reply_count,
      :is_editing_mistake,
      :is_sponsor_mention,
      :is_question,
      :is_positive_comment,
      :is_processed
    ])
    |> validate_required([
      :yt_comment_id,
      :yt_video_id,
      :text,
      :author,
      :published_at,
      :like_count,
      :reply_count,
      :is_editing_mistake,
      :is_sponsor_mention,
      :is_question,
      :is_positive_comment,
      :is_processed
    ])
    |> validate_length(:yt_comment_id, max: 55)
    |> validate_length(:yt_video_id, max: 55)
    |> validate_length(:author, min: 1)
    |> validate_length(:text, min: 1)
  end

  def sentiment_changeset(comment, attrs) do
    comment
    |> cast(attrs, [
      :is_editing_mistake,
      :is_sponsor_mention,
      :is_question,
      :is_positive_comment,
      :is_processed
    ])
    |> validate_required([
      :is_editing_mistake,
      :is_sponsor_mention,
      :is_question,
      :is_positive_comment,
      :is_processed
    ])
  end
end

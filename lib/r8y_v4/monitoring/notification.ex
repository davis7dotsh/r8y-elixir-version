defmodule R8yV4.Monitoring.Notification do
  use Ecto.Schema

  import Ecto.Changeset

  alias R8yV4.Monitoring.{Comment, Video}

  @primary_key {:notification_id, :string, autogenerate: false}
  @derive {Phoenix.Param, key: :notification_id}

  @type_values [:todoist_video_live, :discord_video_live, :discord_flagged_comment]

  schema "notifications" do
    belongs_to(:video, Video,
      references: :yt_video_id,
      foreign_key: :yt_video_id,
      type: :string
    )

    field(:type, Ecto.Enum, values: @type_values)
    field(:success, :boolean)
    field(:message, :string)

    belongs_to(:comment, Comment,
      references: :yt_comment_id,
      foreign_key: :comment_id,
      type: :string
    )

    field(:created_at, :naive_datetime, read_after_writes: true)
  end

  def type_values, do: @type_values

  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:notification_id, :yt_video_id, :type, :success, :message, :comment_id])
    |> validate_required([:notification_id, :yt_video_id, :type, :success, :message])
    |> validate_length(:notification_id, max: 55)
    |> validate_length(:yt_video_id, max: 55)
    |> validate_length(:comment_id, max: 55)
  end
end

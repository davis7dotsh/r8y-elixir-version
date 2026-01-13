defmodule R8yV4.Repo.Migrations.AdjustFlaggedCommentNotificationDedupe do
  use Ecto.Migration

  def up do
    drop_if_exists(
      index(:notifications, [:yt_video_id, :comment_id, :type],
        name: :notifications_unique_flagged_comment
      )
    )

    create(
      unique_index(:notifications, [:yt_video_id, :comment_id, :type],
        name: :notifications_unique_flagged_comment,
        where: "type = 'discord_flagged_comment' AND comment_id IS NOT NULL AND success = true"
      )
    )
  end

  def down do
    drop_if_exists(
      index(:notifications, [:yt_video_id, :comment_id, :type],
        name: :notifications_unique_flagged_comment
      )
    )

    create(
      unique_index(:notifications, [:yt_video_id, :comment_id, :type],
        name: :notifications_unique_flagged_comment,
        where: "type = 'discord_flagged_comment' AND comment_id IS NOT NULL"
      )
    )
  end
end

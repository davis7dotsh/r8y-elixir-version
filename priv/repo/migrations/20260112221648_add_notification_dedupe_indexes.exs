defmodule R8yV4.Repo.Migrations.AddNotificationDedupeIndexes do
  use Ecto.Migration

  def change do
    create(
      unique_index(:notifications, [:yt_video_id, :comment_id, :type],
        name: :notifications_unique_flagged_comment,
        where: "type = 'discord_flagged_comment' AND comment_id IS NOT NULL AND success = true"
      )
    )
  end
end

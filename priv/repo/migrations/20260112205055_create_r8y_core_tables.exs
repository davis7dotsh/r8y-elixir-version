defmodule R8yV4.Repo.Migrations.CreateR8yCoreTables do
  use Ecto.Migration

  def change do
    execute(
      "CREATE TYPE notification_type AS ENUM ('todoist_video_live', 'discord_video_live', 'discord_flagged_comment')",
      "DROP TYPE notification_type"
    )

    create table(:channels, primary_key: false) do
      add(:yt_channel_id, :string, primary_key: true, size: 55)
      add(:name, :text, null: false)
      add(:find_sponsor_prompt, :text, null: false)
      add(:created_at, :naive_datetime, null: false, default: fragment("now()"))
    end

    create table(:videos, primary_key: false) do
      add(:yt_video_id, :string, primary_key: true, size: 55)

      add(:yt_channel_id, references(:channels, column: :yt_channel_id, type: :string),
        null: false
      )

      add(:title, :string, null: false, size: 255)
      add(:description, :text, null: false)
      add(:thumbnail_url, :text, null: false)
      add(:published_at, :naive_datetime, null: false)
      add(:view_count, :integer, null: false)
      add(:like_count, :integer, null: false)
      add(:comment_count, :integer, null: false)
      add(:created_at, :naive_datetime, null: false, default: fragment("now()"))
    end

    create(index(:videos, [:yt_channel_id, :published_at], name: :yt_channel_id_and_published_at))
    create(index(:videos, [:yt_channel_id, :title], name: :videos_channel_title_search))

    create table(:comments, primary_key: false) do
      add(:yt_comment_id, :string, primary_key: true, size: 55)
      add(:yt_video_id, references(:videos, column: :yt_video_id, type: :string), null: false)
      add(:text, :text, null: false)
      add(:author, :text, null: false)
      add(:published_at, :naive_datetime, null: false)
      add(:like_count, :integer, null: false)
      add(:reply_count, :integer, null: false)
      add(:is_editing_mistake, :boolean, null: false)
      add(:is_sponsor_mention, :boolean, null: false)
      add(:is_question, :boolean, null: false)
      add(:is_positive_comment, :boolean, null: false)
      add(:is_processed, :boolean, null: false)
      add(:created_at, :naive_datetime, null: false, default: fragment("now()"))
    end

    create(index(:comments, [:yt_video_id], name: :yt_video_id_comments))
    create(index(:comments, [:yt_comment_id], name: :yt_comment_id))

    create table(:sponsors, primary_key: false) do
      add(:sponsor_id, :string, primary_key: true, size: 55)

      add(:yt_channel_id, references(:channels, column: :yt_channel_id, type: :string),
        null: false
      )

      add(:sponsor_key, :string, null: false, size: 255)
      add(:name, :string, null: false, size: 255)
      add(:created_at, :naive_datetime, null: false, default: fragment("now()"))
    end

    create(index(:sponsors, [:yt_channel_id], name: :yt_channel_id_sponsors))
    create(index(:sponsors, [:sponsor_key], name: :sponsor_key))
    create(index(:sponsors, [:yt_channel_id, :sponsor_key], name: :sponsors_channel_key_search))
    create(index(:sponsors, [:yt_channel_id, :name], name: :sponsors_name_search))

    create table(:sponsor_to_videos, primary_key: false) do
      add(:sponsor_id, references(:sponsors, column: :sponsor_id, type: :string),
        primary_key: true,
        null: false
      )

      add(:yt_video_id, references(:videos, column: :yt_video_id, type: :string),
        primary_key: true,
        null: false
      )

      add(:created_at, :naive_datetime, null: false, default: fragment("now()"))
    end

    create(index(:sponsor_to_videos, [:sponsor_id], name: :sponsor_id_sponsor_to_videos))
    create(index(:sponsor_to_videos, [:yt_video_id], name: :yt_video_id_sponsor_to_videos))

    create table(:notifications, primary_key: false) do
      add(:notification_id, :string, primary_key: true, size: 55)
      add(:yt_video_id, references(:videos, column: :yt_video_id, type: :string), null: false)
      add(:type, :notification_type, null: false)
      add(:success, :boolean, null: false)
      add(:message, :text, null: false)
      add(:comment_id, references(:comments, column: :yt_comment_id, type: :string))
      add(:created_at, :naive_datetime, null: false, default: fragment("now()"))
    end

    create(index(:notifications, [:yt_video_id], name: :yt_video_id_notifs))
  end
end

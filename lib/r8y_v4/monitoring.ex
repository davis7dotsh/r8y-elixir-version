defmodule R8yV4.Monitoring do
  @moduledoc """
  Context for r8y monitoring data (channels, videos, comments, sponsors).
  """

  import Ecto.Query, warn: false

  alias R8yV4.Monitoring.{Channel, Comment, Notification, Sponsor, SponsorToVideo, Video}
  alias R8yV4.Repo

  # ---
  # Channels
  # ---

  def list_channels do
    Channel
    |> order_by([c], asc: c.created_at)
    |> Repo.all()
  end

  def count_channels do
    Repo.aggregate(Channel, :count)
  end

  def get_channel(yt_channel_id), do: Repo.get(Channel, yt_channel_id)
  def get_channel!(yt_channel_id), do: Repo.get!(Channel, yt_channel_id)

  def create_channel(attrs \\ %{}) do
    %Channel{}
    |> Channel.changeset(attrs)
    |> Repo.insert()
  end

  def update_channel(%Channel{} = channel, attrs) do
    channel
    |> Channel.changeset(attrs)
    |> Repo.update()
  end

  def delete_channel(%Channel{} = channel), do: Repo.delete(channel)

  def change_channel(%Channel{} = channel, attrs \\ %{}) do
    Channel.changeset(channel, attrs)
  end

  # ---
  # Videos
  # ---

  def get_video(yt_video_id), do: Repo.get(Video, yt_video_id)
  def get_video!(yt_video_id), do: Repo.get!(Video, yt_video_id)

  def get_video_with_relations!(yt_video_id) do
    yt_video_id
    |> get_video!()
    |> Repo.preload([:channel, :sponsors])
  end

  def list_recent_videos(opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    Video
    |> order_by([v], desc: v.published_at)
    |> limit(^limit)
    |> Repo.all()
    |> Repo.preload([:channel, :sponsors])
  end

  def list_channel_videos(yt_channel_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)

    from(v in Video,
      where: v.yt_channel_id == ^yt_channel_id,
      order_by: [desc: v.published_at],
      limit: ^limit,
      offset: ^offset
    )
    |> Repo.all()
    |> Repo.preload([:sponsors])
  end

  def count_channel_videos(yt_channel_id) when is_binary(yt_channel_id) do
    Repo.aggregate(
      from(v in Video, where: v.yt_channel_id == ^yt_channel_id),
      :count,
      :yt_video_id
    )
  end

  def count_videos do
    Repo.aggregate(Video, :count)
  end

  def get_channel_with_recent_stats(yt_channel_id) when is_binary(yt_channel_id) do
    thirty_days_ago = NaiveDateTime.utc_now() |> NaiveDateTime.add(-30, :day)

    channel = get_channel!(yt_channel_id)

    stats =
      from(v in Video,
        where: v.yt_channel_id == ^yt_channel_id,
        where: v.published_at >= ^thirty_days_ago,
        select: %{video_count: count(v.yt_video_id), total_views: sum(v.view_count)}
      )
      |> Repo.one()

    latest_video =
      from(v in Video,
        where: v.yt_channel_id == ^yt_channel_id,
        where: v.published_at >= ^thirty_days_ago,
        order_by: [desc: v.published_at],
        limit: 1,
        select: %{yt_video_id: v.yt_video_id, title: v.title, view_count: v.view_count}
      )
      |> Repo.one()

    %{
      channel: channel,
      video_count: (stats && stats.video_count) || 0,
      total_views: (stats && stats.total_views) || 0,
      latest_video: latest_video
    }
  end

  def upsert_video(attrs) when is_map(attrs) do
    yt_video_id = Map.get(attrs, :yt_video_id) || Map.get(attrs, "yt_video_id")

    case Repo.get(Video, yt_video_id) do
      nil ->
        case %Video{} |> Video.changeset(attrs) |> Repo.insert() do
          {:ok, video} -> {:ok, video, true}
          {:error, changeset} -> {:error, changeset}
        end

      %Video{} = video ->
        case video |> Video.counts_changeset(attrs) |> Repo.update() do
          {:ok, video} -> {:ok, video, false}
          {:error, changeset} -> {:error, changeset}
        end
    end
  end

  # ---
  # Comments
  # ---

  def get_comment(yt_comment_id), do: Repo.get(Comment, yt_comment_id)

  def list_comments_for_video(yt_video_id, opts \\ []) do
    filter =
      case Keyword.get(opts, :filter, :all) do
        "flagged" -> :flagged
        :flagged -> :flagged
        "unprocessed" -> :unprocessed
        :unprocessed -> :unprocessed
        "sponsor" -> :sponsor
        :sponsor -> :sponsor
        _ -> :all
      end

    sort =
      case Keyword.get(opts, :sort, :recent) do
        "likes" -> :likes
        :likes -> :likes
        _ -> :recent
      end

    limit_value = Keyword.get(opts, :limit)

    query =
      Comment
      |> where([c], c.yt_video_id == ^yt_video_id)

    query =
      case sort do
        :likes -> order_by(query, [c], desc: c.like_count)
        :recent -> order_by(query, [c], desc: c.published_at)
      end

    query =
      case filter do
        :flagged ->
          where(
            query,
            [c],
            c.is_editing_mistake or c.is_sponsor_mention or c.is_question
          )

        :unprocessed ->
          where(query, [c], c.is_processed == false)

        :sponsor ->
          where(query, [c], c.is_sponsor_mention == true)

        :all ->
          query
      end

    query =
      if is_integer(limit_value) do
        limit(query, ^limit_value)
      else
        query
      end

    Repo.all(query)
  end

  def list_channel_sponsor_mentions(yt_channel_id, opts \\ []) do
    limit_value = Keyword.get(opts, :limit, 50)

    from(c in Comment,
      join: v in Video,
      on: v.yt_video_id == c.yt_video_id,
      where: v.yt_channel_id == ^yt_channel_id,
      where: c.is_sponsor_mention == true,
      order_by: [desc: c.published_at],
      limit: ^limit_value,
      select: %{comment: c, video_title: v.title, yt_video_id: v.yt_video_id}
    )
    |> Repo.all()
  end

  def bulk_upsert_comments(yt_video_id, comments) when is_list(comments) do
    entries =
      Enum.map(comments, fn comment ->
        %{
          yt_comment_id: comment.yt_comment_id,
          yt_video_id: yt_video_id,
          text: comment.text,
          author: comment.author,
          published_at: comment.published_at,
          like_count: comment.like_count,
          reply_count: comment.reply_count,
          is_editing_mistake: false,
          is_sponsor_mention: false,
          is_question: false,
          is_positive_comment: false,
          is_processed: false
        }
      end)

    if entries == [] do
      {0, nil}
    else
      Repo.insert_all(Comment, entries,
        on_conflict: {:replace, [:like_count, :reply_count]},
        conflict_target: :yt_comment_id
      )
    end
  end

  def patch_comment_sentiment(yt_comment_id, attrs) when is_map(attrs) do
    comment = Repo.get!(Comment, yt_comment_id)
    attrs = Map.put(attrs, :is_processed, true)

    comment
    |> Comment.sentiment_changeset(attrs)
    |> Repo.update()
  end

  # ---
  # Sponsors
  # ---

  def count_sponsors do
    Repo.aggregate(Sponsor, :count)
  end

  def get_sponsor_by_key(sponsor_key), do: Repo.get_by(Sponsor, sponsor_key: sponsor_key)

  def get_sponsor!(sponsor_id), do: Repo.get!(Sponsor, sponsor_id)

  def get_sponsor_for_video(yt_video_id) do
    from(s in Sponsor,
      join: stv in SponsorToVideo,
      on: stv.sponsor_id == s.sponsor_id,
      where: stv.yt_video_id == ^yt_video_id,
      limit: 1
    )
    |> Repo.one()
  end

  def get_sponsor_details!(sponsor_id) do
    sponsor = Repo.get!(Sponsor, sponsor_id)

    videos =
      from(v in Video,
        join: stv in SponsorToVideo,
        on: stv.yt_video_id == v.yt_video_id,
        where: stv.sponsor_id == ^sponsor_id,
        order_by: [desc: v.published_at]
      )
      |> Repo.all()

    yt_video_ids = Enum.map(videos, & &1.yt_video_id)

    sponsor_mention_comments =
      if yt_video_ids == [] do
        []
      else
        from(c in Comment,
          join: v in Video,
          on: v.yt_video_id == c.yt_video_id,
          where: c.yt_video_id in ^yt_video_ids,
          where: c.is_sponsor_mention == true,
          order_by: [desc: c.published_at],
          select: %{comment: c, video_title: v.title, yt_video_id: v.yt_video_id}
        )
        |> Repo.all()
      end

    total_views = Enum.reduce(videos, 0, fn video, acc -> acc + (video.view_count || 0) end)
    total_ads = length(videos)
    avg_views_per_video = if total_ads > 0, do: round(total_views / total_ads), else: 0
    last_publish_date = videos |> Enum.at(0) |> then(&(&1 && &1.published_at))

    %{
      sponsor: sponsor,
      videos: videos,
      sponsor_mention_comments: sponsor_mention_comments,
      stats: %{
        total_views: total_views,
        total_ads: total_ads,
        avg_views_per_video: avg_views_per_video,
        last_publish_date: last_publish_date
      }
    }
  end

  def list_sponsors_with_stats(opts \\ []) do
    yt_channel_id = Keyword.get(opts, :yt_channel_id)
    limit_value = Keyword.get(opts, :limit)

    Sponsor
    |> sponsors_with_stats_query()
    |> maybe_filter_by_channel(yt_channel_id)
    |> maybe_limit(limit_value)
    |> Repo.all()
    |> Enum.map(&decorate_sponsor_stats_row/1)
  end

  def list_channel_sponsors_with_stats(yt_channel_id) when is_binary(yt_channel_id) do
    list_sponsors_with_stats(yt_channel_id: yt_channel_id)
  end

  defp sponsors_with_stats_query(query) do
    from(s in query,
      left_join: stv in SponsorToVideo,
      on: stv.sponsor_id == s.sponsor_id,
      left_join: v in Video,
      on: v.yt_video_id == stv.yt_video_id,
      group_by: s.sponsor_id,
      order_by: [desc: max(v.published_at)],
      select: %{
        sponsor: s,
        total_views: sum(v.view_count),
        total_videos: count(v.yt_video_id),
        last_video_published_at: max(v.published_at)
      }
    )
  end

  defp maybe_limit(query, limit_value) when is_integer(limit_value) do
    limit(query, ^limit_value)
  end

  defp maybe_limit(query, _), do: query

  defp decorate_sponsor_stats_row(row) do
    last_video_published_at = row.last_video_published_at

    days_ago =
      if is_struct(last_video_published_at, NaiveDateTime) do
        NaiveDateTime.diff(NaiveDateTime.utc_now(), last_video_published_at, :day)
      else
        nil
      end

    total_views = row.total_views || 0
    total_videos = row.total_videos || 0

    %{
      sponsor: row.sponsor,
      total_views: total_views,
      total_videos: total_videos,
      avg_views_per_video: if(total_videos > 0, do: round(total_views / total_videos), else: 0),
      last_video_published_at: last_video_published_at,
      last_video_published_days_ago: days_ago
    }
  end

  def create_sponsor(attrs) when is_map(attrs) do
    sponsor_id = Map.get(attrs, :sponsor_id) || generate_id()
    attrs = Map.put(attrs, :sponsor_id, sponsor_id)

    %Sponsor{}
    |> Sponsor.changeset(attrs)
    |> Repo.insert()
  end

  def attach_sponsor_to_video(%{sponsor_id: sponsor_id, yt_video_id: yt_video_id}) do
    %SponsorToVideo{}
    |> SponsorToVideo.changeset(%{sponsor_id: sponsor_id, yt_video_id: yt_video_id})
    |> Repo.insert(on_conflict: :nothing, conflict_target: [:sponsor_id, :yt_video_id])
  end

  # ---
  # Notifications
  # ---

  def list_notifications_for_video(yt_video_id, opts \\ []) do
    limit_value = Keyword.get(opts, :limit, 50)

    Notification
    |> where([n], n.yt_video_id == ^yt_video_id)
    |> order_by([n], desc: n.created_at)
    |> limit(^limit_value)
    |> Repo.all()
    |> Repo.preload([:comment])
  end

  def list_notifications_for_channel(yt_channel_id, opts \\ []) when is_binary(yt_channel_id) do
    limit_value = Keyword.get(opts, :limit, 50)

    from(n in Notification,
      join: v in Video,
      on: v.yt_video_id == n.yt_video_id,
      where: v.yt_channel_id == ^yt_channel_id,
      order_by: [desc: n.created_at],
      limit: ^limit_value,
      select: %{notification: n, video_title: v.title, yt_video_id: v.yt_video_id}
    )
    |> Repo.all()
  end

  def log_notification(attrs) when is_map(attrs) do
    notification_id = Map.get(attrs, :notification_id) || generate_id()
    attrs = Map.put(attrs, :notification_id, notification_id)

    %Notification{}
    |> Notification.changeset(attrs)
    |> Repo.insert()
  end

  def has_discord_flagged_comment_notification?(yt_video_id, yt_comment_id)
      when is_binary(yt_video_id) and is_binary(yt_comment_id) do
    Repo.exists?(
      from(n in Notification,
        where: n.yt_video_id == ^yt_video_id,
        where: n.comment_id == ^yt_comment_id,
        where: n.type == :discord_flagged_comment
      )
    )
  end

  # ---
  # Search
  # ---

  def search(query, opts \\ []) when is_binary(query) do
    query = normalize_search_query(query)
    limit = Keyword.get(opts, :limit, 4)

    yt_channel_id =
      opts
      |> Keyword.get(:yt_channel_id, "")
      |> normalize_search_query()
      |> case do
        "" -> nil
        id -> id
      end

    if query == "" do
      %{channels: [], sponsors: [], videos: []}
    else
      %{
        channels: search_channels(query, limit: limit),
        sponsors: search_sponsors(query, yt_channel_id: yt_channel_id, limit: limit),
        videos: search_videos(query, yt_channel_id: yt_channel_id, limit: limit)
      }
    end
  end

  def search_channels(query, opts \\ []) when is_binary(query) do
    query = normalize_search_query(query)
    limit = Keyword.get(opts, :limit, 4)

    if query == "" do
      []
    else
      pattern = "%#{query}%"

      from(c in Channel,
        where: ilike(c.name, ^pattern) or ilike(c.yt_channel_id, ^pattern),
        order_by: [asc: c.name],
        limit: ^limit
      )
      |> Repo.all()
    end
  end

  def search_videos(query, opts \\ []) when is_binary(query) do
    query = normalize_search_query(query)
    limit = Keyword.get(opts, :limit, 4)
    yt_channel_id = Keyword.get(opts, :yt_channel_id)

    if query == "" do
      []
    else
      pattern = "%#{query}%"

      Video
      |> where([v], ilike(v.title, ^pattern) or ilike(v.yt_video_id, ^pattern))
      |> maybe_filter_by_channel(yt_channel_id)
      |> order_by([v], desc: v.published_at)
      |> limit(^limit)
      |> Repo.all()
      |> Repo.preload([:channel, :sponsors])
    end
  end

  def search_sponsors(query, opts \\ []) when is_binary(query) do
    query = normalize_search_query(query)
    limit = Keyword.get(opts, :limit, 4)
    yt_channel_id = Keyword.get(opts, :yt_channel_id)

    if query == "" do
      []
    else
      pattern = "%#{query}%"

      Sponsor
      |> where([s], ilike(s.name, ^pattern) or ilike(s.sponsor_key, ^pattern))
      |> maybe_filter_by_channel(yt_channel_id)
      |> order_by([s], asc: s.name)
      |> limit(^limit)
      |> Repo.all()
    end
  end

  defp maybe_filter_by_channel(query, yt_channel_id) do
    if is_binary(yt_channel_id) and yt_channel_id not in [""] do
      where(query, [row], row.yt_channel_id == ^yt_channel_id)
    else
      query
    end
  end

  defp normalize_search_query(nil), do: ""

  defp normalize_search_query(query) when is_binary(query) do
    query
    |> String.trim()
    |> String.slice(0, 80)
  end

  defp normalize_search_query(query) do
    query
    |> to_string()
    |> String.trim()
    |> String.slice(0, 80)
  end

  defp generate_id do
    16
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :lower)
  end
end

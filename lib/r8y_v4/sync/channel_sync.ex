defmodule R8yV4.Sync.ChannelSync do
  @moduledoc false

  require Logger

  alias R8yV4.Integrations.{OpenRouter, YouTube}
  alias R8yV4.Monitoring
  alias R8yV4.Notifications.{Discord, Todoist}

  def sync_all_channels do
    started_at = System.monotonic_time()

    channels = Monitoring.list_channels()

    {success_count, error_count} =
      channels
      |> Task.async_stream(&sync_channel/1, max_concurrency: 2, timeout: :infinity)
      |> Enum.reduce({0, 0}, fn
        {:ok, {successes, errors}}, {success_acc, error_acc} ->
          {success_acc + successes, error_acc + errors}

        {:exit, reason}, {success_acc, error_acc} ->
          Logger.error("channel sync task crashed", reason: inspect(reason))
          {success_acc, error_acc + 1}
      end)

    duration_ms =
      System.monotonic_time()
      |> Kernel.-(started_at)
      |> System.convert_time_unit(:native, :millisecond)

    Logger.info("channel sync completed",
      channels: length(channels),
      videos_synced: success_count,
      videos_failed: error_count,
      duration_ms: duration_ms
    )

    :ok
  end

  def backfill_channel(yt_channel_id, opts \\ []) when is_binary(yt_channel_id) do
    max_videos = opts |> Keyword.get(:max_videos, 1000) |> clamp(1, 2000)

    Logger.info("starting channel backfill", yt_channel_id: yt_channel_id, max_videos: max_videos)

    channel = Monitoring.get_channel(yt_channel_id)

    if is_nil(channel) do
      {:error, :channel_not_found}
    else
      with {:ok, video_ids} <-
             YouTube.get_video_ids_for_channel(yt_channel_id, max_results: max_videos) do
        total_videos = length(video_ids)

        Logger.info("found videos to backfill",
          yt_channel_id: yt_channel_id,
          total_videos: total_videos
        )

        counts =
          video_ids
          |> Task.async_stream(
            fn yt_video_id ->
              sync_video(%{yt_video_id: yt_video_id, yt_channel_id: yt_channel_id}, channel,
                is_backfill: true
              )
            end,
            max_concurrency: 2,
            timeout: :infinity
          )
          |> Enum.reduce(%{success: 0, error: 0}, fn
            {:ok, :ok}, acc ->
              %{acc | success: acc.success + 1}

            {:ok, {:error, _reason}}, acc ->
              %{acc | error: acc.error + 1}

            {:exit, reason}, acc ->
              Logger.error("backfill video task crashed", reason: inspect(reason))
              %{acc | error: acc.error + 1}
          end)

        Logger.info("channel backfill completed",
          yt_channel_id: yt_channel_id,
          videos_synced: counts.success,
          videos_failed: counts.error
        )

        {:ok, counts}
      end
    end
  end

  defp clamp(value, min, max) when is_integer(value) do
    value |> max(min) |> min(max)
  end

  defp sync_channel(channel) do
    case YouTube.get_recent_videos_for_channel(channel.yt_channel_id) do
      {:ok, rss_videos} when is_list(rss_videos) ->
        rss_videos
        |> Enum.map(&Map.put(&1, :yt_channel_id, channel.yt_channel_id))
        |> Task.async_stream(&sync_video(&1, channel), max_concurrency: 2, timeout: :infinity)
        |> Enum.reduce({0, 0}, fn
          {:ok, :ok}, {success_acc, error_acc} ->
            {success_acc + 1, error_acc}

          {:ok, {:error, reason}}, {success_acc, error_acc} ->
            Logger.error("video sync failed",
              yt_video_id: reason[:yt_video_id],
              reason: inspect(reason)
            )

            {success_acc, error_acc + 1}

          {:exit, reason}, {success_acc, error_acc} ->
            Logger.error("video sync crashed", reason: inspect(reason))
            {success_acc, error_acc + 1}
        end)

      {:error, reason} ->
        Logger.error("failed to fetch channel RSS",
          yt_channel_id: channel.yt_channel_id,
          reason: inspect(reason)
        )

        {0, 1}
    end
  end

  defp sync_video(rss_video, channel, opts \\ []) do
    yt_video_id = rss_video.yt_video_id

    Logger.info("syncing video", yt_video_id: yt_video_id)

    video_attrs =
      case YouTube.get_video_details(yt_video_id) do
        {:ok, attrs} ->
          attrs

        {:error, reason} ->
          Logger.debug("using RSS video details fallback",
            yt_video_id: yt_video_id,
            reason: inspect(reason)
          )

          rss_video
      end

    with {:ok, video, was_inserted} <- Monitoring.upsert_video(video_attrs),
         {:ok, sponsor} <- ensure_sponsor(channel, video, video_attrs),
         :ok <- maybe_send_video_live(was_inserted, video, sponsor, opts),
         :ok <- maybe_sync_comments(video, sponsor, opts) do
      :ok
    else
      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, %{yt_video_id: yt_video_id, changeset: changeset}}

      {:error, reason} ->
        {:error, %{yt_video_id: yt_video_id, reason: reason}}
    end
  end

  defp ensure_sponsor(channel, video, video_attrs) do
    case Monitoring.get_sponsor_for_video(video.yt_video_id) do
      %{} = sponsor ->
        {:ok, sponsor}

      nil ->
        maybe_detect_sponsor(channel, video, video_attrs)
    end
  end

  defp maybe_detect_sponsor(channel, video, video_attrs) do
    if OpenRouter.enabled?() do
      with {:ok, %{sponsor_key: sponsor_key, sponsor_name: sponsor_name}}
           when sponsor_key not in [nil, ""] and sponsor_name not in [nil, ""] <-
             OpenRouter.get_sponsor(channel.find_sponsor_prompt, video_attrs.description),
           {:ok, sponsor} <- upsert_sponsor(channel.yt_channel_id, sponsor_key, sponsor_name),
           {:ok, _} <-
             Monitoring.attach_sponsor_to_video(%{
               sponsor_id: sponsor.sponsor_id,
               yt_video_id: video.yt_video_id
             }) do
        {:ok, sponsor}
      else
        _ -> {:ok, nil}
      end
    else
      {:ok, nil}
    end
  end

  defp upsert_sponsor(yt_channel_id, sponsor_key, sponsor_name) do
    case Monitoring.get_sponsor_by_key(sponsor_key) do
      %{} = sponsor ->
        {:ok, sponsor}

      nil ->
        Monitoring.create_sponsor(%{
          yt_channel_id: yt_channel_id,
          sponsor_key: sponsor_key,
          name: sponsor_name
        })
    end
  end

  defp maybe_send_video_live(true, video, sponsor, opts) do
    :ok = Discord.send_video_live(video, sponsor, opts)
    :ok = Todoist.send_video_live(video, sponsor, opts)
    :ok
  end

  defp maybe_send_video_live(false, _video, _sponsor, _opts), do: :ok

  defp maybe_sync_comments(video, sponsor, opts) do
    case YouTube.get_video_comments(video.yt_video_id, max_results: 100) do
      {:ok, comments} when is_list(comments) ->
        _ = Monitoring.bulk_upsert_comments(video.yt_video_id, comments)
        maybe_classify_comments(video, sponsor, opts)

      {:error, :missing_api_key} ->
        Logger.debug("skipping comments sync (missing YOUTUBE_API_KEY)")
        :ok

      {:error, reason} ->
        Logger.error("failed to fetch video comments",
          yt_video_id: video.yt_video_id,
          reason: inspect(reason)
        )

        :ok
    end
  end

  defp maybe_classify_comments(video, sponsor, opts) do
    if OpenRouter.enabled?() do
      sponsor_name = sponsor && sponsor.name

      comments = Monitoring.list_comments_for_video(video.yt_video_id)

      # Process comments sequentially to avoid overwhelming OpenRouter API
      # This runs inside already-concurrent video sync tasks
      comments
      |> Enum.reject(& &1.is_processed)
      |> Enum.each(fn comment ->
        classify_comment(comment, video, sponsor_name, opts)
      end)

      :ok
    else
      :ok
    end
  end

  defp classify_comment(comment, video, sponsor_name, opts) do
    case OpenRouter.classify_comment(comment.text, sponsor_name) do
      {:ok, flags} when is_map(flags) ->
        case Monitoring.patch_comment_sentiment(comment.yt_comment_id, flags) do
          {:ok, patched_comment} ->
            :ok = maybe_send_flagged_comment_notification(comment, patched_comment, video, opts)
            :ok

          {:error, %Ecto.Changeset{} = changeset} ->
            Logger.debug("comment sentiment patch failed",
              yt_comment_id: comment.yt_comment_id,
              changeset: inspect(changeset)
            )

            :ok
        end

      {:error, reason} ->
        Logger.debug("comment classification failed",
          yt_comment_id: comment.yt_comment_id,
          reason: inspect(reason)
        )

        :ok
    end
  end

  defp maybe_send_flagged_comment_notification(original_comment, patched_comment, video, opts) do
    was_flagged = flagged?(patched_comment)
    already_flagged = flagged?(original_comment)

    if was_flagged and not already_flagged do
      if opts[:is_backfill] do
        :ok
      else
        Discord.send_flagged_comment(patched_comment, video)
      end
    else
      :ok
    end
  end

  defp flagged?(comment) do
    comment.is_editing_mistake or comment.is_sponsor_mention or comment.is_question
  end
end

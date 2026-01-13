defmodule Mix.Tasks.R8y.Backfill do
  use Mix.Task

  import Mix.Ecto

  alias R8yV4.Sync.ChannelSync

  @shortdoc "Backfill videos for a YouTube channel"

  @moduledoc """
  Backfills up to N videos for a given YouTube channel.

  This uses the YouTube Data API uploads playlist (requires `YOUTUBE_API_KEY`)
  to fetch video IDs, then runs the regular sync logic with `is_backfill: true`
  so "video live" notifications are suppressed.

  ## Usage

      mix r8y.backfill YT_CHANNEL_ID --max-videos 200

  Options:

    - `--max-videos` (default: 1000, max: 2000)
  """

  @switches [max_videos: :integer]

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, argv, _} = OptionParser.parse(args, strict: @switches)

    case argv do
      [yt_channel_id] ->
        ensure_repo(R8yV4.Repo, [])

        max_videos = Keyword.get(opts, :max_videos, 1000)

        case ChannelSync.backfill_channel(yt_channel_id, max_videos: max_videos) do
          {:ok, %{success: success, error: error}} ->
            Mix.shell().info("Backfill completed: #{success} succeeded, #{error} failed")

          {:error, :channel_not_found} ->
            Mix.raise("Channel not found in DB: #{yt_channel_id}")

          {:error, :missing_api_key} ->
            Mix.raise("Missing YOUTUBE_API_KEY (required for backfill)")

          {:error, reason} ->
            Mix.raise("Backfill failed: #{inspect(reason)}")
        end

      _ ->
        Mix.raise("Usage: mix r8y.backfill YT_CHANNEL_ID [--max-videos N]")
    end
  end
end

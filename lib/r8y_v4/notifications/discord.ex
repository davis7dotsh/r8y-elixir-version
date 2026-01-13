defmodule R8yV4.Notifications.Discord do
  @moduledoc false

  require Logger

  alias R8yV4.Monitoring

  def enabled? do
    System.get_env("NOTIFICATIONS_ENABLED") in ["true", "1"]
  end

  def send_video_live(video, sponsor, opts \\ []) do
    if opts[:is_backfill] do
      Logger.debug("Skipping Discord notification for backfill video")
      :ok
    else
      with true <- enabled?(),
           webhook_url when webhook_url not in [nil, ""] <- System.get_env("DISCORD_WEBHOOK_URL"),
           message <- video_live_message(video, sponsor),
           {:ok, _} <- post_webhook(webhook_url, message) do
        _ =
          Monitoring.log_notification(%{
            yt_video_id: video.yt_video_id,
            type: :discord_video_live,
            success: true,
            message: "Message sent to Discord"
          })

        :ok
      else
        false ->
          :ok

        nil ->
          Logger.warning("Discord enabled but DISCORD_WEBHOOK_URL missing")
          :ok

        "" ->
          Logger.warning("Discord enabled but DISCORD_WEBHOOK_URL missing")
          :ok

        {:error, reason} ->
          Logger.error("Failed to send Discord notification", reason: inspect(reason))

          _ =
            Monitoring.log_notification(%{
              yt_video_id: video.yt_video_id,
              type: :discord_video_live,
              success: false,
              message: "Failed to send message to Discord: #{inspect(reason)}"
            })

          :ok
      end
    end
  end

  def send_flagged_comment(comment, video) do
    with true <- enabled?(),
         false <- flagged_comment_already_notified?(comment, video),
         webhook_url when webhook_url not in [nil, ""] <- System.get_env("DISCORD_WEBHOOK_URL"),
         message <- flagged_comment_message(comment, video),
         {:ok, _} <- post_webhook(webhook_url, message) do
      _ =
        Monitoring.log_notification(%{
          yt_video_id: video.yt_video_id,
          type: :discord_flagged_comment,
          success: true,
          message: "Flagged comment message sent to Discord",
          comment_id: comment.yt_comment_id
        })

      :ok
    else
      false ->
        :ok

      true ->
        :ok

      nil ->
        Logger.warning("Discord enabled but DISCORD_WEBHOOK_URL missing")
        :ok

      "" ->
        Logger.warning("Discord enabled but DISCORD_WEBHOOK_URL missing")
        :ok

      {:error, reason} ->
        Logger.error("Failed to send Discord flagged comment", reason: inspect(reason))

        _ =
          Monitoring.log_notification(%{
            yt_video_id: video.yt_video_id,
            type: :discord_flagged_comment,
            success: false,
            message: "Failed to send flagged comment message to Discord: #{inspect(reason)}",
            comment_id: comment.yt_comment_id
          })

        :ok
    end
  end

  defp flagged_comment_already_notified?(comment, video) do
    case Monitoring.has_discord_flagged_comment_notification?(
           video.yt_video_id,
           comment.yt_comment_id
         ) do
      true -> true
      false -> false
    end
  end

  defp post_webhook(url, message) do
    case Req.post(url, json: %{content: message}) do
      {:ok, %Req.Response{status: status} = response} when status in 200..299 ->
        {:ok, response}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, exception} ->
        {:error, {:request_error, exception}}
    end
  end

  defp mention_prefix do
    case System.get_env("DISCORD_ROLE_ID") do
      nil -> ""
      "" -> ""
      role_id -> "<@&#{role_id}> "
    end
  end

  defp video_live_message(video, sponsor) do
    sponsor_name = sponsor && sponsor.name

    """
    #{mention_prefix()}video just went live: *#{video.title}*

    video sponsor: **#{sponsor_name || "no sponsor"}**

    video link: https://www.youtube.com/watch?v=#{video.yt_video_id}

    ```
    ────────────────────────────────────────
    ```
    """
  end

  defp flagged_comment_message(comment, video) do
    """
    #{mention_prefix()}flagged comment from *#{comment.author || "unknown"}*

    left at: #{format_datetime(comment.published_at)}

    comment text: **#{comment.text}**

    like count: #{comment.like_count || "unknown"}

    comment link: <https://www.youtube.com/watch?v=#{video.yt_video_id}&lc=#{comment.yt_comment_id}>

    ```
    ────────────────────────────────────────
    ```
    """
  end

  defp format_datetime(%NaiveDateTime{} = naive) do
    naive
    |> NaiveDateTime.to_iso8601()
    |> Kernel.<>("Z")
  end

  defp format_datetime(_), do: "unknown"
end

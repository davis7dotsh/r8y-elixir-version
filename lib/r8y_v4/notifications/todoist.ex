defmodule R8yV4.Notifications.Todoist do
  @moduledoc false

  require Logger

  alias R8yV4.Monitoring

  @api_base_url "https://api.todoist.com/rest/v2"

  def enabled? do
    System.get_env("NOTIFICATIONS_ENABLED") in ["true", "1"]
  end

  def send_video_live(video, sponsor, opts \\ []) do
    if opts[:is_backfill] do
      Logger.debug("Skipping Todoist notification for backfill video")
      :ok
    else
      with true <- enabled?(),
           token when token not in [nil, ""] <- System.get_env("TODOIST_API_TOKEN"),
           message <- todoist_task_content(video, sponsor),
           {:ok, _} <- create_task(token, message) do
        _ =
          Monitoring.log_notification(%{
            yt_video_id: video.yt_video_id,
            type: :todoist_video_live,
            success: true,
            message: "Video live task added to Todoist"
          })

        :ok
      else
        false ->
          :ok

        nil ->
          Logger.warning("Todoist enabled but TODOIST_API_TOKEN missing")
          :ok

        "" ->
          Logger.warning("Todoist enabled but TODOIST_API_TOKEN missing")
          :ok

        {:error, reason} ->
          Logger.error("Failed to send Todoist notification", reason: inspect(reason))

          _ =
            Monitoring.log_notification(%{
              yt_video_id: video.yt_video_id,
              type: :todoist_video_live,
              success: false,
              message: "Failed to add task to Todoist: #{inspect(reason)}"
            })

          :ok
      end
    end
  end

  defp create_task(token, content) do
    headers = [{"authorization", "Bearer #{token}"}]

    body =
      %{
        content: content,
        due_string: "today",
        labels: ["youtube"]
      }
      |> maybe_put_project_id(todoist_project_id())

    case Req.post(@api_base_url <> "/tasks", headers: headers, json: body) do
      {:ok, %Req.Response{status: status} = response} when status in 200..299 ->
        {:ok, response}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, exception} ->
        {:error, {:request_error, exception}}
    end
  end

  defp todoist_project_id do
    case System.get_env("TODOIST_PROJECT_ID") do
      nil ->
        nil

      "" ->
        nil

      value ->
        case Integer.parse(value) do
          {parsed, ""} -> parsed
          _ -> value
        end
    end
  end

  defp maybe_put_project_id(body, nil), do: body
  defp maybe_put_project_id(body, ""), do: body
  defp maybe_put_project_id(body, project_id), do: Map.put(body, :project_id, project_id)

  defp todoist_task_content(video, sponsor) do
    sponsor_name = sponsor && sponsor.name

    "https://www.youtube.com/watch?v=#{video.yt_video_id} is live, sponsored by #{sponsor_name || "no one"}"
  end
end

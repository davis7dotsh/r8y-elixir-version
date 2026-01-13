defmodule R8yV4.Integrations.YouTube do
  @moduledoc false

  require Logger

  @rss_base_url "https://www.youtube.com/feeds/videos.xml"
  @api_base_url "https://www.googleapis.com/youtube/v3"

  def api_key do
    System.get_env("YOUTUBE_API_KEY") || System.get_env("YT_API_KEY")
  end

  def get_recent_videos_for_channel(yt_channel_id) when is_binary(yt_channel_id) do
    url = "#{@rss_base_url}?channel_id=#{yt_channel_id}"

    case Req.get(url) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, parse_rss(body)}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, exception} ->
        {:error, {:request_error, exception}}
    end
  end

  def get_video_details(yt_video_id) when is_binary(yt_video_id) do
    case api_key() do
      nil ->
        {:error, :missing_api_key}

      api_key ->
        params = %{
          "part" => "snippet,statistics,contentDetails",
          "id" => yt_video_id,
          "key" => api_key
        }

        case Req.get(@api_base_url <> "/videos", params: params) do
          {:ok, %Req.Response{status: 200, body: %{"items" => [item | _]}}} ->
            {:ok, parse_video_details(item)}

          {:ok, %Req.Response{status: 200, body: %{"items" => []}}} ->
            {:error, :not_found}

          {:ok, %Req.Response{status: status, body: body}} ->
            {:error, {:http_error, status, body}}

          {:error, exception} ->
            {:error, {:request_error, exception}}
        end
    end
  end

  def get_video_comments(yt_video_id, opts \\ []) when is_binary(yt_video_id) do
    max_results = opts |> Keyword.get(:max_results, 20) |> clamp(1, 100)

    case api_key() do
      nil ->
        {:error, :missing_api_key}

      api_key ->
        params = %{
          "part" => "snippet,replies",
          "videoId" => yt_video_id,
          "order" => "relevance",
          "maxResults" => Integer.to_string(max_results),
          "textFormat" => "plainText",
          "key" => api_key
        }

        case Req.get(@api_base_url <> "/commentThreads", params: params) do
          {:ok, %Req.Response{status: 200, body: %{"items" => items}}} when is_list(items) ->
            {:ok, Enum.flat_map(items, &parse_comment_thread/1)}

          {:ok, %Req.Response{status: status, body: body}} ->
            {:error, {:http_error, status, body}}

          {:error, exception} ->
            {:error, {:request_error, exception}}
        end
    end
  end

  def get_video_ids_for_channel(yt_channel_id, opts \\ []) when is_binary(yt_channel_id) do
    max_results = opts |> Keyword.get(:max_results, 50) |> clamp(1, 2000)

    case api_key() do
      nil ->
        {:error, :missing_api_key}

      api_key ->
        with {:ok, uploads_playlist_id} <- fetch_uploads_playlist_id(yt_channel_id, api_key),
             {:ok, video_ids} <-
               fetch_playlist_video_ids(uploads_playlist_id, api_key, max_results) do
          {:ok, video_ids}
        end
    end
  end

  defp fetch_uploads_playlist_id(yt_channel_id, api_key) do
    params = %{
      "part" => "contentDetails",
      "id" => yt_channel_id,
      "key" => api_key
    }

    case Req.get(@api_base_url <> "/channels", params: params) do
      {:ok, %Req.Response{status: 200, body: %{"items" => [item | _]}}} ->
        uploads_playlist_id = get_in(item, ["contentDetails", "relatedPlaylists", "uploads"])

        if is_binary(uploads_playlist_id) and uploads_playlist_id not in [""] do
          {:ok, uploads_playlist_id}
        else
          {:error, :uploads_playlist_not_found}
        end

      {:ok, %Req.Response{status: 200, body: %{"items" => []}}} ->
        {:error, :channel_not_found}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, exception} ->
        {:error, {:request_error, exception}}
    end
  end

  defp fetch_playlist_video_ids(playlist_id, api_key, max_results) do
    do_fetch_playlist_video_ids(playlist_id, api_key, nil, max_results, [])
  end

  defp do_fetch_playlist_video_ids(_playlist_id, _api_key, _page_token, remaining, acc)
       when remaining <= 0 do
    {:ok, Enum.reverse(acc)}
  end

  defp do_fetch_playlist_video_ids(playlist_id, api_key, page_token, remaining, acc) do
    page_size = clamp(remaining, 1, 50)

    params = %{
      "part" => "contentDetails",
      "playlistId" => playlist_id,
      "maxResults" => Integer.to_string(page_size),
      "key" => api_key
    }

    params =
      if is_binary(page_token) and page_token not in [""] do
        Map.put(params, "pageToken", page_token)
      else
        params
      end

    case Req.get(@api_base_url <> "/playlistItems", params: params) do
      {:ok, %Req.Response{status: 200, body: %{"items" => items} = body}} when is_list(items) ->
        ids =
          items
          |> Enum.map(&get_in(&1, ["contentDetails", "videoId"]))
          |> Enum.filter(&(is_binary(&1) and &1 not in [""]))

        acc = Enum.reduce(ids, acc, fn id, acc -> [id | acc] end)

        next_page_token = body["nextPageToken"]
        remaining = remaining - length(ids)

        cond do
          remaining <= 0 ->
            {:ok, Enum.reverse(acc)}

          ids == [] ->
            {:ok, Enum.reverse(acc)}

          not is_binary(next_page_token) or next_page_token in [""] ->
            {:ok, Enum.reverse(acc)}

          true ->
            do_fetch_playlist_video_ids(playlist_id, api_key, next_page_token, remaining, acc)
        end

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, exception} ->
        {:error, {:request_error, exception}}
    end
  end

  defp clamp(value, min, max) when is_integer(value) do
    value |> max(min) |> min(max)
  end

  defp parse_rss(body) do
    xml =
      cond do
        is_binary(body) -> body
        is_list(body) -> List.to_string(body)
        true -> to_string(body)
      end

    entry_regex = ~r/<entry>(.*?)<\/entry>/s

    entry_regex
    |> Regex.scan(xml, capture: :all_but_first)
    |> Enum.flat_map(fn [entry_xml] ->
      video_id = match_first(entry_xml, ~r/<yt:videoId>([^<]+)<\/yt:videoId>/)
      title = match_first(entry_xml, ~r/<title>([^<]+)<\/title>/)
      published_at = match_first(entry_xml, ~r/<published>([^<]+)<\/published>/)

      if is_nil(video_id) or is_nil(title) or is_nil(published_at) do
        []
      else
        description =
          match_first(entry_xml, ~r/<media:description>([^<]+)<\/media:description>/) || ""

        thumbnail_url =
          match_first(entry_xml, ~r/<media:thumbnail[^>]+url=\"([^\"]+)\"/) || ""

        view_count =
          match_first(entry_xml, ~r/<media:statistics[^>]+views=\"([^\"]+)\"/) |> parse_int()

        like_count =
          match_first(entry_xml, ~r/<media:starRating[^>]+count=\"([^\"]+)\"/) |> parse_int()

        [
          %{
            yt_video_id: video_id,
            title: title,
            description: description,
            thumbnail_url: thumbnail_url,
            published_at: parse_datetime(published_at),
            view_count: view_count,
            like_count: like_count,
            comment_count: 0
          }
        ]
      end
    end)
  end

  defp match_first(xml, regex) do
    case Regex.run(regex, xml, capture: :all_but_first) do
      [match] -> match
      _ -> nil
    end
  end

  defp parse_video_details(item) do
    snippet = Map.get(item, "snippet") || %{}
    stats = Map.get(item, "statistics") || %{}
    thumbnails = Map.get(snippet, "thumbnails") || %{}

    thumbnail_url =
      get_in(thumbnails, ["high", "url"]) ||
        get_in(thumbnails, ["default", "url"]) ||
        ""

    %{
      yt_channel_id: Map.get(snippet, "channelId"),
      yt_video_id: Map.get(item, "id"),
      title: Map.get(snippet, "title") || "",
      description: Map.get(snippet, "description") || "",
      thumbnail_url: thumbnail_url,
      published_at: Map.get(snippet, "publishedAt") |> parse_datetime(),
      view_count: Map.get(stats, "viewCount") |> parse_int(),
      like_count: Map.get(stats, "likeCount") |> parse_int(),
      comment_count: Map.get(stats, "commentCount") |> parse_int()
    }
  end

  defp parse_comment_thread(%{"id" => comment_id, "snippet" => snippet})
       when is_binary(comment_id) and is_map(snippet) do
    top_level = get_in(snippet, ["topLevelComment", "snippet"]) || %{}

    reply_count = Map.get(snippet, "totalReplyCount") || 0

    [
      %{
        yt_comment_id: comment_id,
        text: Map.get(top_level, "textDisplay") || "",
        author: Map.get(top_level, "authorDisplayName") || "",
        published_at: Map.get(top_level, "publishedAt") |> parse_datetime(),
        like_count: Map.get(top_level, "likeCount") || 0,
        reply_count: reply_count
      }
    ]
  end

  defp parse_comment_thread(_), do: []

  defp parse_datetime(nil), do: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

  defp parse_datetime(value) when is_integer(value) do
    value
    |> DateTime.from_unix!(:millisecond)
    |> DateTime.to_naive()
    |> NaiveDateTime.truncate(:second)
  end

  defp parse_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} ->
        datetime |> DateTime.to_naive() |> NaiveDateTime.truncate(:second)

      {:error, _} ->
        NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    end
  end

  defp parse_int(nil), do: 0

  defp parse_int(value) when is_integer(value), do: value

  defp parse_int(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _rest} -> int
      :error -> 0
    end
  end

  defp parse_int(value) do
    Logger.debug("unexpected int value", value: value)
    0
  end
end

defmodule R8yV4.Integrations.OpenRouter do
  @moduledoc """
  LLM integration for sponsor detection and comment classification.

  Uses OpenRouter API with OPENROUTER_API_KEY environment variable.
  """

  require Logger

  @base_url "https://openrouter.ai/api/v1"
  @default_model "minimax/minimax-m2.1"

  def api_key do
    System.get_env("OPENROUTER_API_KEY")
  end

  def enabled? do
    api_key() not in [nil, ""]
  end

  def base_url do
    System.get_env("OPENROUTER_BASE_URL") || @base_url
  end

  def model do
    System.get_env("OPENROUTER_MODEL") || @default_model
  end

  @doc """
  Attempts to extract a sponsor from a video's description.

  Returns an empty sponsor result when the model indicates there is no sponsor
  (for example, `{\"sponsorName\": \"no sponsor\"}`), so the caller can avoid
  persisting placeholder sponsor rows.

  Returns:

      {:ok, %{sponsor_key: "https://soydev.link/convex", sponsor_name: "convex"}}

  or `{:error, reason}`.
  """
  def get_sponsor(sponsor_prompt, video_description, opts \\ [])
      when is_binary(sponsor_prompt) and is_binary(video_description) do
    with true <- enabled?(),
         prompt <- sponsor_prompt(sponsor_prompt, String.downcase(video_description)),
         {:ok, content} <- chat_completion(prompt, opts),
         {:ok, decoded} <- decode_json(content),
         {:ok, sponsor} <- normalize_sponsor(decoded) do
      {:ok, sponsor}
    else
      false ->
        {:error, :not_configured}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Classifies a YouTube comment.

  Returns:

      {:ok,
       %{is_editing_mistake: false, is_sponsor_mention: false, is_question: false,
         is_positive_comment: false}}

  or `{:error, reason}`.
  """
  def classify_comment(comment_text, video_sponsor, opts \\ []) when is_binary(comment_text) do
    with true <- enabled?(),
         prompt <- comment_prompt(comment_text, video_sponsor),
         {:ok, content} <- chat_completion(prompt, opts),
         {:ok, decoded} <- decode_json(content) do
      {:ok, normalize_comment_flags(decoded)}
    else
      false ->
        {:error, :not_configured}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp chat_completion(prompt, opts) when is_binary(prompt) do
    headers = [
      {"authorization", "Bearer #{api_key()}"},
      {"content-type", "application/json"}
    ]

    body = %{
      "model" => model(),
      "messages" => [
        %{"role" => "user", "content" => prompt}
      ],
      "reasoning" => %{"enabled" => true}
    }

    req_options = Keyword.get(opts, :req_options, [])

    request_options =
      [
        headers: headers,
        json: body,
        retry: :transient,
        max_retries: 2,
        receive_timeout: 60_000
      ]
      |> Keyword.merge(req_options)

    url = base_url() <> "/chat/completions"
    Logger.debug("OpenRouter request", url: url, model: model())

    case Req.post(url, request_options) do
      {:ok,
       %Req.Response{
         status: 200,
         body: %{"choices" => [%{"message" => %{"content" => content}} | _]}
       }}
      when is_binary(content) ->
        {:ok, content}

      {:ok, %Req.Response{status: 200, body: body}} ->
        Logger.warning("OpenRouter unexpected 200 response shape", body: inspect(body))
        {:error, {:unexpected_response, body}}

      {:ok, %Req.Response{status: status, body: body}} ->
        Logger.warning("OpenRouter chat completion failed", status: status, body: inspect(body))
        {:error, {:http_error, status, body}}

      {:error, exception} ->
        Logger.warning("OpenRouter request error", error: inspect(exception))
        {:error, {:request_error, exception}}
    end
  end

  defp sponsor_prompt(sponsor_prompt, video_description) do
    """
    Parse this youtube video's description to find the video's sponsor.
    You are looking for the sponsor's name and a key to identify the sponsor in the db.
    Both the key and name should be lowercase.

    The following will tell you how to get each of those for this channel:
    #{sponsor_prompt}

    The video description is:
    #{video_description}

    Return ONLY a JSON object in this format:
    {"sponsorName": "...", "sponsorKey": "..."}
    """
  end

  defp comment_prompt(comment, video_sponsor) do
    sponsor_text =
      case video_sponsor do
        sponsor when is_binary(sponsor) and sponsor not in [""] -> sponsor
        _ -> "null"
      end

    """
    Read this comment decide if it mentions an editing mistake (something wrong with the video's audio, video, title, thumbnail, or description), the video's sponsor, and/or is a question.
    Also decide if the comment is generally positive or negative.

    The video's sponsor is #{sponsor_text}

    The comment is:
    #{comment}

    Return ONLY a JSON object in this format:
    {"isEditingMistake": false, "isSponsorMention": false, "isQuestion": false, "isPositiveComment": false}
    """
  end

  defp decode_json(content) when is_binary(content) do
    content = content |> String.trim() |> strip_code_fences()

    case Jason.decode(content) do
      {:ok, decoded} when is_map(decoded) ->
        {:ok, decoded}

      {:error, _} ->
        case Regex.run(~r/\{.*\}/s, content) do
          [json] ->
            case Jason.decode(json) do
              {:ok, decoded} when is_map(decoded) -> {:ok, decoded}
              {:ok, decoded} -> {:error, {:unexpected_json, decoded}}
              {:error, err} -> {:error, {:invalid_json, err}}
            end

          _ ->
            {:error, :invalid_json}
        end

      {:ok, decoded} ->
        {:error, {:unexpected_json, decoded}}
    end
  end

  defp strip_code_fences(content) do
    content
    |> String.trim()
    |> String.trim_leading("```json")
    |> String.trim_leading("```")
    |> String.trim_trailing("```")
    |> String.trim()
  end

  defp normalize_sponsor(decoded) when is_map(decoded) do
    sponsor_name =
      decoded["sponsorName"] ||
        decoded["sponsor_name"] ||
        decoded["sponsor"] ||
        decoded["name"]

    sponsor_key =
      decoded["sponsorKey"] ||
        decoded["sponsor_key"] ||
        decoded["key"]

    sponsor_name = sponsor_name |> normalize_string() |> String.downcase()
    sponsor_key = sponsor_key |> normalize_string() |> String.downcase()

    if sponsor_name in ["", "no sponsor", "none", "no one"] do
      {:ok, %{sponsor_key: "", sponsor_name: ""}}
    else
      {:ok, %{sponsor_key: sponsor_key, sponsor_name: sponsor_name}}
    end
  end

  defp normalize_string(nil), do: ""
  defp normalize_string(value) when is_binary(value), do: String.trim(value)
  defp normalize_string(value), do: value |> to_string() |> String.trim()

  defp normalize_comment_flags(decoded) when is_map(decoded) do
    %{
      is_editing_mistake: boolify(decoded["isEditingMistake"] || decoded["is_editing_mistake"]),
      is_sponsor_mention: boolify(decoded["isSponsorMention"] || decoded["is_sponsor_mention"]),
      is_question: boolify(decoded["isQuestion"] || decoded["is_question"]),
      is_positive_comment: boolify(decoded["isPositiveComment"] || decoded["is_positive_comment"])
    }
  end

  defp boolify(true), do: true
  defp boolify(false), do: false
  defp boolify("true"), do: true
  defp boolify("false"), do: false
  defp boolify(1), do: true
  defp boolify(0), do: false
  defp boolify(_), do: false
end

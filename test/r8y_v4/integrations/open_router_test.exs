defmodule R8yV4.Integrations.OpenRouterTest do
  use ExUnit.Case, async: false

  alias R8yV4.Integrations.OpenRouter

  setup do
    original_api_key = System.get_env("OPENROUTER_API_KEY")
    original_model = System.get_env("OPENROUTER_MODEL")

    System.put_env("OPENROUTER_API_KEY", "test_key")
    System.put_env("OPENROUTER_MODEL", "test-model")

    on_exit(fn ->
      restore_env("OPENROUTER_API_KEY", original_api_key)
      restore_env("OPENROUTER_MODEL", original_model)
    end)

    :ok
  end

  test "get_sponsor/3 normalizes sponsor JSON" do
    plug = fn conn ->
      body =
        Jason.encode!(%{
          "choices" => [
            %{
              "message" => %{
                "content" =>
                  Jason.encode!(%{
                    "sponsorName" => "Sevalla",
                    "sponsorKey" => "https://soydev.link/SeVaLLa"
                  })
              }
            }
          ]
        })

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(200, body)
    end

    assert {:ok, %{sponsor_name: "sevalla", sponsor_key: "https://soydev.link/sevalla"}} =
             OpenRouter.get_sponsor("prompt", "desc", req_options: [plug: plug])
  end

  test "get_sponsor/3 returns empty sponsor for no sponsor" do
    plug = fn conn ->
      body =
        Jason.encode!(%{
          "choices" => [
            %{
              "message" => %{
                "content" =>
                  Jason.encode!(%{
                    "sponsorName" => "no sponsor",
                    "sponsorKey" => "https://t3.gg"
                  })
              }
            }
          ]
        })

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(200, body)
    end

    assert {:ok, %{sponsor_name: "", sponsor_key: ""}} =
             OpenRouter.get_sponsor("prompt", "desc", req_options: [plug: plug])
  end

  test "classify_comment/3 parses code-fenced JSON" do
    content = """
    ```json
    {"isEditingMistake": true, "isSponsorMention": true, "isQuestion": false, "isPositiveComment": "false"}
    ```
    """

    plug = fn conn ->
      body =
        Jason.encode!(%{
          "choices" => [
            %{
              "message" => %{
                "content" => content
              }
            }
          ]
        })

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(200, body)
    end

    assert {:ok,
            %{
              is_editing_mistake: true,
              is_sponsor_mention: true,
              is_question: false,
              is_positive_comment: false
            }} =
             OpenRouter.classify_comment("comment", "g2i", req_options: [plug: plug])
  end

  test "returns not_configured when OPENROUTER_API_KEY missing" do
    original_api_key = System.get_env("OPENROUTER_API_KEY")
    System.delete_env("OPENROUTER_API_KEY")

    on_exit(fn -> restore_env("OPENROUTER_API_KEY", original_api_key) end)

    assert {:error, :not_configured} = OpenRouter.get_sponsor("prompt", "desc")
    assert {:error, :not_configured} = OpenRouter.classify_comment("comment", nil)
  end

  defp restore_env(_key, nil), do: :ok

  defp restore_env(key, value) do
    System.put_env(key, value)
  end
end

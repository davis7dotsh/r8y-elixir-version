defmodule R8yV4Web.ChannelLive.IndexTest do
  use R8yV4Web.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias R8yV4.Monitoring

  test "shows dashboard links for channels", %{conn: conn} do
    {:ok, _channel} =
      Monitoring.create_channel(%{
        yt_channel_id: "chan_1",
        name: "Test Channel",
        find_sponsor_prompt: "Find sponsors"
      })

    {:ok, view, _html} = live(conn |> log_in(), ~p"/channels")

    assert has_element?(view, "#channels")
    assert has_element?(view, "#view-chan_1")
  end
end

defmodule R8yV4Web.VideoLive.IndexTest do
  use R8yV4Web.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias R8yV4.Monitoring

  test "shows details links for videos", %{conn: conn} do
    {:ok, _channel} =
      Monitoring.create_channel(%{
        yt_channel_id: "chan_1",
        name: "Test Channel",
        find_sponsor_prompt: "Find sponsors"
      })

    {:ok, _video, true} =
      Monitoring.upsert_video(%{
        yt_video_id: "vid_1",
        yt_channel_id: "chan_1",
        title: "Test Video",
        description: "A description",
        thumbnail_url: "https://example.com/thumb.jpg",
        published_at: ~N[2026-01-12 00:00:00],
        view_count: 10,
        like_count: 1,
        comment_count: 0
      })

    {:ok, view, _html} = live(conn |> log_in(), ~p"/videos")

    assert has_element?(view, "#videos")
    assert has_element?(view, "#details-vid_1")
  end
end

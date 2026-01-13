defmodule R8yV4Web.SearchLive.IndexTest do
  use R8yV4Web.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias R8yV4.Monitoring

  test "searches channels, sponsors, and videos", %{conn: conn} do
    {:ok, _channel} =
      Monitoring.create_channel(%{
        yt_channel_id: "chan_1",
        name: "Test Channel",
        find_sponsor_prompt: "Find sponsors"
      })

    {:ok, _other_channel} =
      Monitoring.create_channel(%{
        yt_channel_id: "chan_2",
        name: "Other Channel",
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

    {:ok, _sponsor} =
      Monitoring.create_sponsor(%{
        sponsor_id: "spon_1",
        yt_channel_id: "chan_1",
        sponsor_key: "https://example.com",
        name: "Example Sponsor"
      })

    {:ok, view, _html} = live(conn |> log_in(), ~p"/search")

    assert has_element?(view, "#search")
    assert has_element?(view, "#search-form")

    view
    |> element("#search-form")
    |> render_change(%{search: %{query: "Test", yt_channel_id: ""}})

    assert has_element?(view, "#search-channel-chan_1")
    refute has_element?(view, "#search-sponsor-spon_1")
    assert has_element?(view, "#search-video-vid_1")

    view
    |> element("#search-form")
    |> render_change(%{search: %{query: "Example", yt_channel_id: "chan_1"}})

    assert has_element?(view, "#search-sponsor-spon_1")
    refute has_element?(view, "#search-channel-chan_2")

    view
    |> element("#search-form")
    |> render_change(%{search: %{query: "", yt_channel_id: ""}})

    refute has_element?(view, "#search-channel-chan_1")
    refute has_element?(view, "#search-video-vid_1")
    refute has_element?(view, "#search-sponsor-spon_1")
  end
end

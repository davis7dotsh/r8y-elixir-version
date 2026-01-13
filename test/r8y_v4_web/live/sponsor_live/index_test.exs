defmodule R8yV4Web.SponsorLive.IndexTest do
  use R8yV4Web.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias R8yV4.Monitoring

  test "lists sponsors with stats", %{conn: conn} do
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
        view_count: 100,
        like_count: 10,
        comment_count: 1
      })

    {:ok, sponsor} =
      Monitoring.create_sponsor(%{
        sponsor_id: "spon_1",
        yt_channel_id: "chan_1",
        sponsor_key: "https://example.com",
        name: "Example Sponsor"
      })

    {:ok, _} =
      Monitoring.attach_sponsor_to_video(%{
        sponsor_id: sponsor.sponsor_id,
        yt_video_id: "vid_1"
      })

    {:ok, view, _html} = live(conn |> log_in(), ~p"/sponsors")

    assert has_element?(view, "#sponsors-index")
    assert has_element?(view, "#sponsors-table")
    assert has_element?(view, "#sponsors-index-sponsor-spon_1")

    view
    |> element("#sponsor-filter-form")
    |> render_change(%{filter: %{yt_channel_id: "chan_1"}})

    assert has_element?(view, "#sponsors-index-sponsor-spon_1")
  end
end

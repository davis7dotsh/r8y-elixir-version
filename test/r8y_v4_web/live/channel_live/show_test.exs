defmodule R8yV4Web.ChannelLive.ShowTest do
  use R8yV4Web.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias R8yV4.Monitoring
  alias R8yV4.Monitoring.Comment
  alias R8yV4.Repo

  test "renders channel dashboard tabs", %{conn: conn} do
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

    {:ok, _sponsor} =
      Monitoring.create_sponsor(%{
        sponsor_id: "spon_1",
        yt_channel_id: "chan_1",
        sponsor_key: "https://example.com",
        name: "Example Sponsor"
      })

    {:ok, _} =
      Monitoring.attach_sponsor_to_video(%{
        sponsor_id: "spon_1",
        yt_video_id: "vid_1"
      })

    Repo.insert!(
      %Comment{}
      |> Comment.changeset(%{
        yt_comment_id: "c1",
        yt_video_id: "vid_1",
        text: "sponsor mention",
        author: "Alice",
        published_at: ~N[2026-01-12 01:00:00],
        like_count: 2,
        reply_count: 0,
        is_editing_mistake: false,
        is_sponsor_mention: true,
        is_question: false,
        is_positive_comment: false,
        is_processed: true
      })
    )

    _ =
      Monitoring.log_notification(%{
        yt_video_id: "vid_1",
        type: :discord_video_live,
        success: true,
        message: "sent"
      })

    {:ok, view, _html} = live(conn |> log_in(), ~p"/channels/chan_1")

    assert has_element?(view, "#channel-show")
    assert has_element?(view, "#channel-tabs")
    assert has_element?(view, "#channel-videos")
    assert has_element?(view, "#video-vid_1")

    view |> element("#tab-sponsors") |> render_click()
    assert_patch(view, ~p"/channels/chan_1?tab=sponsors")
    assert has_element?(view, "#channel-sponsors")
    assert has_element?(view, "#sponsor-spon_1")

    view |> element("#tab-mentions") |> render_click()
    assert_patch(view, ~p"/channels/chan_1?tab=mentions")
    assert has_element?(view, "#channel-mentions")
    assert has_element?(view, "#open-mention-c1")

    view |> element("#tab-notifications") |> render_click()
    assert_patch(view, ~p"/channels/chan_1?tab=notifications")
    assert has_element?(view, "#channel-notifications")
  end
end

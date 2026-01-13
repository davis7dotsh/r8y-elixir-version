defmodule R8yV4Web.VideoLive.ShowTest do
  use R8yV4Web.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias R8yV4.Monitoring
  alias R8yV4.Monitoring.Comment
  alias R8yV4.Repo

  test "filters comments by flags and processed state", %{conn: conn} do
    {:ok, _channel} =
      Monitoring.create_channel(%{
        yt_channel_id: "chan_1",
        name: "Test Channel",
        find_sponsor_prompt: "Find sponsors"
      })

    {:ok, video, true} =
      Monitoring.upsert_video(%{
        yt_video_id: "vid_1",
        yt_channel_id: "chan_1",
        title: "Test Video",
        description: "A description",
        thumbnail_url: "https://example.com/thumb.jpg",
        published_at: ~N[2026-01-12 00:00:00],
        view_count: 10,
        like_count: 1,
        comment_count: 3
      })

    Repo.insert!(
      %Comment{}
      |> Comment.changeset(%{
        yt_comment_id: "c1",
        yt_video_id: video.yt_video_id,
        text: "flagged comment",
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

    Repo.insert!(
      %Comment{}
      |> Comment.changeset(%{
        yt_comment_id: "c2",
        yt_video_id: video.yt_video_id,
        text: "boring comment",
        author: "Bob",
        published_at: ~N[2026-01-12 02:00:00],
        like_count: 0,
        reply_count: 0,
        is_editing_mistake: false,
        is_sponsor_mention: false,
        is_question: false,
        is_positive_comment: false,
        is_processed: true
      })
    )

    Repo.insert!(
      %Comment{}
      |> Comment.changeset(%{
        yt_comment_id: "c3",
        yt_video_id: video.yt_video_id,
        text: "needs processing",
        author: "Casey",
        published_at: ~N[2026-01-12 03:00:00],
        like_count: 0,
        reply_count: 0,
        is_editing_mistake: false,
        is_sponsor_mention: false,
        is_question: false,
        is_positive_comment: false,
        is_processed: false
      })
    )

    Repo.insert!(
      %Comment{}
      |> Comment.changeset(%{
        yt_comment_id: "c4",
        yt_video_id: video.yt_video_id,
        text: "nice video",
        author: "Dana",
        published_at: ~N[2026-01-12 04:00:00],
        like_count: 0,
        reply_count: 0,
        is_editing_mistake: false,
        is_sponsor_mention: false,
        is_question: false,
        is_positive_comment: true,
        is_processed: true
      })
    )

    {:ok, view, _html} = live(conn |> log_in(), ~p"/videos/#{video.yt_video_id}")

    assert has_element?(view, "#video-show")
    assert has_element?(view, "#comments")

    assert has_element?(view, "#open-comment-c1")
    assert has_element?(view, "#open-comment-c2")
    assert has_element?(view, "#open-comment-c3")
    assert has_element?(view, "#open-comment-c4")

    view |> element("#filter-flagged") |> render_click()
    assert_patch(view, ~p"/videos/#{video.yt_video_id}?filter=flagged")

    assert has_element?(view, "#open-comment-c1")
    refute has_element?(view, "#open-comment-c2")
    refute has_element?(view, "#open-comment-c3")
    refute has_element?(view, "#open-comment-c4")

    view |> element("#filter-unprocessed") |> render_click()
    assert_patch(view, ~p"/videos/#{video.yt_video_id}?filter=unprocessed")

    assert has_element?(view, "#open-comment-c3")
    refute has_element?(view, "#open-comment-c1")
    refute has_element?(view, "#open-comment-c2")
    refute has_element?(view, "#open-comment-c4")

    view |> element("#filter-all") |> render_click()
    assert_patch(view, ~p"/videos/#{video.yt_video_id}")

    assert has_element?(view, "#open-comment-c1")
    assert has_element?(view, "#open-comment-c2")
    assert has_element?(view, "#open-comment-c3")
    assert has_element?(view, "#open-comment-c4")
  end
end

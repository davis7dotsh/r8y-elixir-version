# Migration Notes (r8y-v4)

## What exists so far

- DB schema migrated via Ecto migrations (channels, videos, comments, sponsors, sponsor_to_videos, notifications).
- `/channels` LiveView: manage monitored channels.
- `/channels/:yt_channel_id` LiveView: channel dashboard (videos, sponsors, sponsor mentions, notifications).
- `/sponsors` LiveView: browse all sponsors (optional channel filter).
- `/sponsors/:sponsor_id` LiveView: sponsor details (stats, videos, sponsor-mention comments).
- `/videos` LiveView: list recent synced videos.
- `/videos/:yt_video_id` LiveView: view a video’s comments, flags, and notification log.
- Oban cron job (`R8yV4.Workers.ChannelSync`) runs every 20 minutes.
  - Sync logic lives in `R8yV4.Sync.ChannelSync`.
  - Uses the YouTube RSS feed to discover recent videos.
  - Uses the YouTube Data API (if `YOUTUBE_API_KEY` is set) to fetch video stats + top comments.

## Integrations

- `R8yV4.Integrations.YouTube`:
  - RSS discovery does not require auth.
  - Comment + stats fetching requires `YOUTUBE_API_KEY`.
- `R8yV4.Integrations.OpenRouter`:
  - Implemented using the OpenRouter Chat Completions API (OpenAI-compatible).
  - Uses `Req` with `retry: :transient` + `max_retries: 2`.
  - Defaults:
    - Base URL: `https://openrouter.ai/api/v1`
    - Model: `openai/gpt-oss-120b`
    - Headers: `HTTP-Referer=https://r8y.app`, `X-Title=r8y`
  - Returns empty sponsor (`%{sponsor_key: "", sponsor_name: ""}`) when the model indicates there is no sponsor (e.g. `"no sponsor"`).
- `R8yV4.Notifications.Discord` / `R8yV4.Notifications.Todoist`:
  - Use `NOTIFICATIONS_ENABLED=true` to turn on.
  - Discord uses a webhook (`DISCORD_WEBHOOK_URL`).
  - Todoist can target a project via `TODOIST_PROJECT_ID`.

## Next steps

- Add LiveViews for:
  - (done) per-channel detail page (videos, sponsors, mentions, notifications).
  - (done) per-sponsor detail page (videos, aggregate stats, mention comments).
  - (done) search (`/search`) for channels/videos/sponsors.

- Implement real OpenRouter calls:
  - sponsor extraction (`get_sponsor/2`)
  - comment classification (`classify_comment/2`)
- Add backfill tooling (Oban worker or mix task) similar to legacy `backfillChannel`. (done: `mix r8y.backfill`)

## Recent decisions

- Flagged comment notifications:
  - “Flagged” now matches the legacy UI (editing mistake, sponsor mention, question).
  - Discord flagged comment notifications fire when a comment transitions from unflagged → flagged after AI processing.
  - Dedupe uses a Postgres partial unique index on `(yt_video_id, comment_id, type)` for `discord_flagged_comment`.

# R8yV4

All the stuff for how ralph was used is in the RALPH_LAND directory. It's stupid simple. I had sonnet make the prompt and the script. Then I let it run. That's it.

## Dev setup

From the repo root:

- `mix deps.get` (first time)
- `mix ecto.setup` (creates db, runs migrations, seeds data)
- `mix phx.server`

Then visit http://localhost:4000.

### Database commands

- `mix ecto.setup` — create database, run migrations, and seed data
- `mix ecto.reset` — drop database and run setup again (wipes all data)
- `mix run priv/repo/seeds.exs` — seed channels (can be run multiple times safely)

Useful pages:

- `/channels` — manage monitored YouTube channels
- `/videos` — recent synced videos (click “Details”)
- `/sponsors` — browse detected sponsors (filter by channel)
- `/search` — quick search across channels, plus videos/sponsors
- `/videos/:yt_video_id` — video details (comments, flags, notifications)

## Background jobs (Oban)

- Oban is configured with `Oban.Plugins.Cron` to enqueue `R8yV4.Workers.ChannelSync` every 20 minutes.
- The worker syncs recent videos via the public YouTube RSS feed and upserts them into Postgres.
- If `YOUTUBE_API_KEY` is set, it also fetches video details + top comments.
- If `NOTIFICATIONS_ENABLED` is true, it can send Discord/Todoist notifications (see env vars below).

## Backfill

To ingest older videos for an existing channel (matching the legacy backfill CLI):

- `mix r8y.backfill YT_CHANNEL_ID --max-videos 200`

Notes:

- Requires `YOUTUBE_API_KEY` (YouTube Data API v3) because it uses the channel uploads playlist.
- Runs the normal sync pipeline with `is_backfill: true` so “video live” + flagged-comment notifications are suppressed.

## Environment variables

Required:

- `DATABASE_URL` — Postgres connection string
- `AUTH_PASSWORD` — password for accessing the web UI (all routes require authentication)

Optional for dev/test:

- `DATABASE_URL_TEST` — optional override for tests

Planned (placeholders; configure later):

- `YOUTUBE_API_KEY` — YouTube Data API v3 key (required for comment sync + accurate stats)
- `YT_API_KEY` — legacy alias for `YOUTUBE_API_KEY`
- `OPENROUTER_API_KEY` — enables AI features (sponsor detection + comment classification)
- `OPENROUTER_MODEL` — optional model override (default: `openai/gpt-oss-120b`)
- `OPENROUTER_BASE_URL` — optional base URL override (default: `https://openrouter.ai/api/v1`)
- `OPENROUTER_HTTP_REFERER` — optional `HTTP-Referer` header (default: `https://r8y.app`)
- `OPENROUTER_TITLE` — optional `X-Title` header (default: `r8y`)
- `NOTIFICATIONS_ENABLED` — set to `true` or `1` to enable Discord/Todoist notifications
- `DISCORD_WEBHOOK_URL` — Discord webhook URL for notifications
- `DISCORD_ROLE_ID` — optional Discord role ID to mention
- `TODOIST_API_TOKEN` — Todoist personal API token
- `TODOIST_PROJECT_ID` — optional numeric project id; tasks will be created inside this project when set

## Learn more

- Official website: https://www.phoenixframework.org/
- Guides: https://hexdocs.pm/phoenix/overview.html
- Docs: https://hexdocs.pm/phoenix
- Forum: https://elixirforum.com/c/phoenix-forum
- Source: https://github.com/phoenixframework/phoenix

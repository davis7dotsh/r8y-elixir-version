# Migrate r8y to Elixir/Phoenix

Migrate the entire TypeScript/Bun application in `legacy-reference/` to a new Elixir/Phoenix application in `r8y-v4/`.

## Project Overview

**What it does**: YouTube channel monitoring system that syncs channel data, videos, comments, and identifies sponsor mentions using AI. Sends notifications via Discord and Todoist when specific events occur (new videos, flagged comments).

**Current stack** (TypeScript):

- SvelteKit web app with Tailwind CSS
- Effect-TS for functional composition
- Bun background worker that syncs every 20 minutes
- Drizzle ORM with PostgreSQL
- Discord & Todoist integrations
- YouTube Data API v3
- OpenRouter for AI (sponsor detection, comment analysis)

**Target stack** (Elixir):

- Phoenix LiveView web app (replaces SvelteKit)
- Phoenix contexts for business logic (replaces Effect-TS patterns)
- GenServer/Oban for background jobs (replaces Bun worker)
- Ecto with PostgreSQL (replaces Drizzle)
- Same external APIs: Discord, Todoist, YouTube, OpenRouter

## Database Schema

Based on `legacy-reference/packages/db/src/schema.ts`:

**Tables**:

1. `channels` - YouTube channels being monitored
2. `videos` - Videos from monitored channels
3. `comments` - Comments on videos (with AI-analyzed flags)
4. `sponsors` - Identified sponsors mentioned in videos
5. `sponsor_to_videos` - Many-to-many relationship
6. `notifications` - Notification log (Discord/Todoist)

See schema.ts for full column definitions, indexes, and relationships.

## Core Functionality to Migrate

all the functionality of the old app should be migrated to the new app. document how to use it when you're done.

## Environment Variables

A `.env` file exists at the project root with a working `DATABASE_URL` for testing. Use this for development and testing.

For other env vars you need (YouTube API, Discord, Todoist, OpenRouter, etc.):

1. Document them in your code/notes with descriptions
2. Use placeholder/dummy values in examples
3. **NEVER** ask for real API keys - assume they'll be configured later

The `.env` file is gitignored, so it's safe to use.

## Progress Tracking & State

The migration may be in progress, check for notes:

Keep notes wherever they make sense to you - in READMEs, standalone markdown files, code comments, TODO files, decision logs, etc. Organize your state tracking in whatever way helps you work effectively. These notes are YOUR workspace.

Some suggestions:

- Track migration progress and decisions
- Document why you chose certain approaches
- Note useful btca learnings
- Keep blockers and questions visible
- Write implementation notes alongside code

Be creative with how you organize information!

## Guidelines

- **Use btca liberally** - You have elixir, phoenix, and ecto resources configured. Ask them questions!
- **Incremental progress** - Build one feature at a time, leave notes as you go
- **Idiomatic Elixir** - Follow Phoenix/Elixir conventions, don't just translate TypeScript
- **Keep it simple** - Phoenix has built-in solutions; use them instead of over-engineering
- **Document decisions** - When you make architectural choices, note them where it makes sense
- **Working directory** - All new code goes in `r8y-v4/`
- **Choose your own path** - You decide the migration approach and architecture. Use your judgment!

## Success Criteria

- [ ] Phoenix app runs with `mix phx.server`
- [ ] Database migrations run successfully
- [ ] Background sync job works (Oban)
- [ ] Web dashboard displays channels, videos, sponsors, comments
- [ ] Can add/edit channels through UI
- [ ] External APIs integrate correctly (YouTube, Discord, Todoist, OpenRouter)
- [ ] AI analysis processes comments correctly
- [ ] Notifications send appropriately

---

## Loop Instructions

**IMPORTANT**: You are running in an automated loop via `opencode-loop.sh`. 

**This means**:
- You can finish your work at ANY point - the loop will automatically continue
- As long as `STATUS.md` is NOT `completed` or `blocked`, another iteration will run
- You don't need to complete everything in one go - work incrementally!
- Focus on making meaningful progress each iteration, then finish naturally
- The next iteration will pick up where you left off

**On each iteration**:
1. Work towards completing the migration above (make incremental progress)
2. Leave notes/state wherever makes sense as you work
3. When COMPLETELY done with ALL work, update `STATUS.md` to `Status: completed`
4. If blocked, update `STATUS.md` to `Status: blocked` with a reason
5. Otherwise, just finish when you've made good progress - the loop continues automatically!

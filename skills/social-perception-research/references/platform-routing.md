# Platform routing

Use the best approved read path that already exists in the active environment. Claude and Codex
may expose different tools; preserve the research contract instead of hard-coding one tool name.

## Route order

1. Purpose-built official API, connector, or approved platform CLI
2. A healthy Agent Reach backend when `agent-reach doctor --json` is available
3. An existing user-controlled signed-in browser session when the task permits it
4. Public web search and direct page reads
5. A disclosed evidence gap

Agent Reach is an optional selector and health checker, not evidence by itself. Cite the platform
post, video, page, or comment returned by its active backend.

Before reporting that access is unavailable, inspect the current tools, approved project access
pointers, and existing runtime configuration without exposing secret values or locations.

## Platform focus

- **YouTube:** videos, Shorts, channel framing, thumbnails, transcripts, visible comments, and
  recurring search suggestions. Separate official uploads from reactions and fan edits.
- **Reddit:** posts, comments, subreddit context, recurring questions, praise, criticism, memes,
  and community-specific language.
- **X:** posts, quote posts, threads, visible replies, hashtags, and fast-moving event language.
- **Instagram:** account framing, posts, Reels, captions, visible comments, styling, and brand
  associations. Disclose search limitations rather than treating account search as full-post search.
- **Facebook:** public or approved-session pages, posts, visible group activity, local fan pages,
  and event circulation. Do not imply access to arbitrary private group content.
- **LinkedIn:** company, professional, partner, event, campaign, and industry framing. Do not use
  LinkedIn as a proxy for fan sentiment.
- **Web and local media:** official sites, local-language press, event pages, ticketing, brand
  pages, and search results used to interpret platform observations.

## Local-market queries

- Search in English and every requested market's primary language.
- Include official spellings, transliterations, common misspellings, member names, campaign names,
  venue or event names, and category terms relevant to the business question.
- Keep original wording in notes. Translate only after preserving the source term.

## Evidence record

For each retained example, record:

- direct URL and access date
- platform and account or community
- market and language
- source type: official, media, brand, partner, fan, or criticism
- observed image element or keyword
- why the example supports the finding

Use visible counts only as source-level context. Never generalize a convenience sample into a
population estimate.

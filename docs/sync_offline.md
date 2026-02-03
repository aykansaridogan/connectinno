# Offline Sync & Conflict Strategy

Overview
- The client reads notes from a local Hive box for instant offline availability.
- A background fetch merges notes from Supabase into the Hive local cache.
- Create/update/delete attempts write-through to Supabase; on failure the repository falls back to local-only changes.

Conflict handling
- Current strategy: last-write-wins based on `updated_at` timestamp for server-originated updates.
- Recommended improvement: use `updated_at` comparison and present merge conflicts to the user, or use operational transforms for collaborative editing.

Next steps
- Add a background sync worker to periodically reconcile local changes with the server.
- Track a `dirty` flag for local-only changes and push them when online.

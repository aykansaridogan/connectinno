# AI Features — Product Vision for Connectinno Notes

This document outlines practical, privacy-conscious AI features that can be integrated into the Connectinno note-taking app and a small, local placeholder implementation included in the backend for demonstration.

1) Candidate AI features
- Summarization: generate short summaries of long notes (single-paragraph or key-sentences).
- Action item extraction: detect TODOs, tasks, deadlines, and generate task cards.
- Auto-tagging & categorization: infer tags and categories to improve search and filtering.
- Smart search (semantic): embed notes with a vector model for semantic search and similarity-based suggestions.
- Meeting minutes assistant: convert meeting transcripts into concise minutes, decisions, and action items.
- Rewrite, translate, or tone-adjust: create different versions (short/long/formal/informal) of a note.

2) Privacy & security
- Keep user data private: perform inference server-side under the project owner's control or use client-side on-device models where possible.
- Do not store LLM prompts or responses unless the user opts in; log only metadata for analytics.
- Use per-user credentials and ensure endpoints validate the Supabase user token. RLS and server-side checks should prevent cross-user access.

3) Integration options (short-term → long-term)
- Short-term (fast): integrate an API-based LLM (OpenAI, Anthropic) from a server endpoint; use the existing backend to mediate requests and protect keys.
- Mid-term: use embeddings + vector DB (Supabase Vector, pgvector) to enable semantic search and similarity recommendations.
- Long-term: on-device models for offline, private inference (Quantized LLMs) plus server-based heavy-lift LLMs for larger tasks.

4) Example architecture for Summarization (recommended)
- Client requests summary: `POST /notes/{note_id}/summary` with Bearer token.
- Backend verifies ownership (already implemented) then either:
  - Calls a hosted LLM (OpenAI) or an Edge Function that performs summarization, or
  - Calls an internal summarizer (placeholder) for offline or cheap operation.
- The backend returns structured data: `{summary: "...", model: "openai/gpt-4o", tokens: 42}` as available.

5) Cost & UX considerations
- Indicate cost and latency for AI features in the UI; provide ability to enable/disable per-user or per-organization.
- Provide usage limits and caching for repeated requests (avoid repeated identical LLM calls).

6) Roadmap & experiments
- Phase 1: Summarization + Auto-tagging with server-side LLM.
- Phase 2: Embeddings for semantic search and related-note suggestions.
- Phase 3: On-device fallback model for offline summarization and privacy-sensitive users.

7) Demo placeholder included
- The repository contains a tiny, deterministic summarizer in `backend/app/ai_utils.py` and a protected endpoint `POST /notes/{note_id}/summary` that returns a short extractive summary. This is a low-cost demo to show the end-to-end flow and ownership protection.

---
If you'd like, I can integrate a production LLM (OpenAI, Anthropic), set up embedding storage in Supabase, and add UI controls for the features above.
